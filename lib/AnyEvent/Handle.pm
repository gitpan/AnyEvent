package AnyEvent::Handle;

no warnings;
use strict;

use AnyEvent ();
use AnyEvent::Util qw(WSAWOULDBLOCK);
use Scalar::Util ();
use Carp ();
use Fcntl ();
use Errno qw/EAGAIN EINTR/;

=head1 NAME

AnyEvent::Handle - non-blocking I/O on file handles via AnyEvent

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

   use AnyEvent;
   use AnyEvent::Handle;

   my $cv = AnyEvent->condvar;

   my $handle =
      AnyEvent::Handle->new (
         fh => \*STDIN,
         on_eof => sub {
            $cv->broadcast;
         },
      );

   # send some request line
   $handle->push_write ("getinfo\015\012");

   # read the response line
   $handle->push_read (line => sub {
      my ($handle, $line) = @_;
      warn "read line <$line>\n";
      $cv->send;
   });

   $cv->recv;

=head1 DESCRIPTION

This module is a helper module to make it easier to do event-based I/O on
filehandles. For utility functions for doing non-blocking connects and accepts
on sockets see L<AnyEvent::Util>.

In the following, when the documentation refers to of "bytes" then this
means characters. As sysread and syswrite are used for all I/O, their
treatment of characters applies to this module as well.

All callbacks will be invoked with the handle object as their first
argument.

=head1 METHODS

=over 4

=item B<new (%args)>

The constructor supports these arguments (all as key => value pairs).

=over 4

=item fh => $filehandle [MANDATORY]

The filehandle this L<AnyEvent::Handle> object will operate on.

NOTE: The filehandle will be set to non-blocking (using
AnyEvent::Util::fh_nonblocking).

=item on_eof => $cb->($self)

Set the callback to be called on EOF.

While not mandatory, it is highly recommended to set an eof callback,
otherwise you might end up with a closed socket while you are still
waiting for data.

=item on_error => $cb->($self)

This is the fatal error callback, that is called when, well, a fatal error
occurs, such as not being able to resolve the hostname, failure to connect
or a read error.

The object will not be in a usable state when this callback has been
called.

On callback entrance, the value of C<$!> contains the operating system
error (or C<ENOSPC>, C<EPIPE> or C<EBADMSG>).

While not mandatory, it is I<highly> recommended to set this callback, as
you will not be notified of errors otherwise. The default simply calls
die.

=item on_read => $cb->($self)

This sets the default read callback, which is called when data arrives
and no read request is in the queue.

To access (and remove data from) the read buffer, use the C<< ->rbuf >>
method or access the C<$self->{rbuf}> member directly.

When an EOF condition is detected then AnyEvent::Handle will first try to
feed all the remaining data to the queued callbacks and C<on_read> before
calling the C<on_eof> callback. If no progress can be made, then a fatal
error will be raised (with C<$!> set to C<EPIPE>).

=item on_drain => $cb->()

This sets the callback that is called when the write buffer becomes empty
(or when the callback is set and the buffer is empty already).

To append to the write buffer, use the C<< ->push_write >> method.

=item rbuf_max => <bytes>

If defined, then a fatal error will be raised (with C<$!> set to C<ENOSPC>)
when the read buffer ever (strictly) exceeds this size. This is useful to
avoid denial-of-service attacks.

For example, a server accepting connections from untrusted sources should
be configured to accept only so-and-so much data that it cannot act on
(for example, when expecting a line, an attacker could send an unlimited
amount of data without a callback ever being called as long as the line
isn't finished).

=item read_size => <bytes>

The default read block size (the amount of bytes this module will try to read
on each [loop iteration). Default: C<4096>.

=item low_water_mark => <bytes>

Sets the amount of bytes (default: C<0>) that make up an "empty" write
buffer: If the write reaches this size or gets even samller it is
considered empty.

=item tls => "accept" | "connect" | Net::SSLeay::SSL object

When this parameter is given, it enables TLS (SSL) mode, that means it
will start making tls handshake and will transparently encrypt/decrypt
data.

TLS mode requires Net::SSLeay to be installed (it will be loaded
automatically when you try to create a TLS handle).

For the TLS server side, use C<accept>, and for the TLS client side of a
connection, use C<connect> mode.

You can also provide your own TLS connection object, but you have
to make sure that you call either C<Net::SSLeay::set_connect_state>
or C<Net::SSLeay::set_accept_state> on it before you pass it to
AnyEvent::Handle.

See the C<starttls> method if you need to start TLs negotiation later.

=item tls_ctx => $ssl_ctx

Use the given Net::SSLeay::CTX object to create the new TLS connection
(unless a connection object was specified directly). If this parameter is
missing, then AnyEvent::Handle will use C<AnyEvent::Handle::TLS_CTX>.

=back

=cut

sub new {
   my $class = shift;

   my $self = bless { @_ }, $class;

   $self->{fh} or Carp::croak "mandatory argument fh is missing";

   AnyEvent::Util::fh_nonblocking $self->{fh}, 1;

   if ($self->{tls}) {
      require Net::SSLeay;
      $self->starttls (delete $self->{tls}, delete $self->{tls_ctx});
   }

   $self->on_eof   (delete $self->{on_eof}  ) if $self->{on_eof};
   $self->on_error (delete $self->{on_error}) if $self->{on_error};
   $self->on_drain (delete $self->{on_drain}) if $self->{on_drain};
   $self->on_read  (delete $self->{on_read} ) if $self->{on_read};

   $self->start_read;

   $self
}

sub _shutdown {
   my ($self) = @_;

   delete $self->{rw};
   delete $self->{ww};
   delete $self->{fh};
}

sub error {
   my ($self) = @_;

   {
      local $!;
      $self->_shutdown;
   }

   if ($self->{on_error}) {
      $self->{on_error}($self);
   } else {
      Carp::croak "AnyEvent::Handle uncaught fatal error: $!";
   }
}

=item $fh = $handle->fh

This method returns the file handle of the L<AnyEvent::Handle> object.

=cut

sub fh { $_[0]->{fh} }

=item $handle->on_error ($cb)

Replace the current C<on_error> callback (see the C<on_error> constructor argument).

=cut

sub on_error {
   $_[0]{on_error} = $_[1];
}

=item $handle->on_eof ($cb)

Replace the current C<on_eof> callback (see the C<on_eof> constructor argument).

=cut

sub on_eof {
   $_[0]{on_eof} = $_[1];
}

#############################################################################

=back

=head2 WRITE QUEUE

AnyEvent::Handle manages two queues per handle, one for writing and one
for reading.

The write queue is very simple: you can add data to its end, and
AnyEvent::Handle will automatically try to get rid of it for you.

When data could be written and the write buffer is shorter then the low
water mark, the C<on_drain> callback will be invoked.

=over 4

=item $handle->on_drain ($cb)

Sets the C<on_drain> callback or clears it (see the description of
C<on_drain> in the constructor).

=cut

sub on_drain {
   my ($self, $cb) = @_;

   $self->{on_drain} = $cb;

   $cb->($self)
      if $cb && $self->{low_water_mark} >= length $self->{wbuf};
}

=item $handle->push_write ($data)

Queues the given scalar to be written. You can push as much data as you
want (only limited by the available memory), as C<AnyEvent::Handle>
buffers it independently of the kernel.

=cut

sub _drain_wbuf {
   my ($self) = @_;

   if (!$self->{ww} && length $self->{wbuf}) {

      Scalar::Util::weaken $self;

      my $cb = sub {
         my $len = syswrite $self->{fh}, $self->{wbuf};

         if ($len >= 0) {
            substr $self->{wbuf}, 0, $len, "";

            $self->{on_drain}($self)
               if $self->{low_water_mark} >= length $self->{wbuf}
                  && $self->{on_drain};

            delete $self->{ww} unless length $self->{wbuf};
         } elsif ($! != EAGAIN && $! != EINTR && $! != WSAWOULDBLOCK) {
            $self->error;
         }
      };

      # try to write data immediately
      $cb->();

      # if still data left in wbuf, we need to poll
      $self->{ww} = AnyEvent->io (fh => $self->{fh}, poll => "w", cb => $cb)
         if length $self->{wbuf};
   };
}

our %WH;

sub register_write_type($$) {
   $WH{$_[0]} = $_[1];
}

sub push_write {
   my $self = shift;

   if (@_ > 1) {
      my $type = shift;

      @_ = ($WH{$type} or Carp::croak "unsupported type passed to AnyEvent::Handle::push_write")
           ->($self, @_);
   }

   if ($self->{filter_w}) {
      $self->{filter_w}->($self, \$_[0]);
   } else {
      $self->{wbuf} .= $_[0];
      $self->_drain_wbuf;
   }
}

=item $handle->push_write (type => @args)

=item $handle->unshift_write (type => @args)

Instead of formatting your data yourself, you can also let this module do
the job by specifying a type and type-specific arguments.

Predefined types are (if you have ideas for additional types, feel free to
drop by and tell us):

=over 4

=item netstring => $string

Formats the given value as netstring
(http://cr.yp.to/proto/netstrings.txt, this is not a recommendation to use them).

=back

=cut

register_write_type netstring => sub {
   my ($self, $string) = @_;

   sprintf "%d:%s,", (length $string), $string
};

=item AnyEvent::Handle::register_write_type type => $coderef->($self, @args)

This function (not method) lets you add your own types to C<push_write>.
Whenever the given C<type> is used, C<push_write> will invoke the code
reference with the handle object and the remaining arguments.

The code reference is supposed to return a single octet string that will
be appended to the write buffer.

Note that this is a function, and all types registered this way will be
global, so try to use unique names.

=cut

#############################################################################

=back

=head2 READ QUEUE

AnyEvent::Handle manages two queues per handle, one for writing and one
for reading.

The read queue is more complex than the write queue. It can be used in two
ways, the "simple" way, using only C<on_read> and the "complex" way, using
a queue.

In the simple case, you just install an C<on_read> callback and whenever
new data arrives, it will be called. You can then remove some data (if
enough is there) from the read buffer (C<< $handle->rbuf >>) if you want
or not.

In the more complex case, you want to queue multiple callbacks. In this
case, AnyEvent::Handle will call the first queued callback each time new
data arrives and removes it when it has done its job (see C<push_read>,
below).

This way you can, for example, push three line-reads, followed by reading
a chunk of data, and AnyEvent::Handle will execute them in order.

Example 1: EPP protocol parser. EPP sends 4 byte length info, followed by
the specified number of bytes which give an XML datagram.

   # in the default state, expect some header bytes
   $handle->on_read (sub {
      # some data is here, now queue the length-header-read (4 octets)
      shift->unshift_read_chunk (4, sub {
         # header arrived, decode
         my $len = unpack "N", $_[1];

         # now read the payload
         shift->unshift_read_chunk ($len, sub {
            my $xml = $_[1];
            # handle xml
         });
      });
   });

Example 2: Implement a client for a protocol that replies either with
"OK" and another line or "ERROR" for one request, and 64 bytes for the
second request. Due tot he availability of a full queue, we can just
pipeline sending both requests and manipulate the queue as necessary in
the callbacks:

   # request one
   $handle->push_write ("request 1\015\012");

   # we expect "ERROR" or "OK" as response, so push a line read
   $handle->push_read_line (sub {
      # if we got an "OK", we have to _prepend_ another line,
      # so it will be read before the second request reads its 64 bytes
      # which are already in the queue when this callback is called
      # we don't do this in case we got an error
      if ($_[1] eq "OK") {
         $_[0]->unshift_read_line (sub {
            my $response = $_[1];
            ...
         });
      }
   });

   # request two
   $handle->push_write ("request 2\015\012");

   # simply read 64 bytes, always
   $handle->push_read_chunk (64, sub {
      my $response = $_[1];
      ...
   });

=over 4

=cut

sub _drain_rbuf {
   my ($self) = @_;

   if (
      defined $self->{rbuf_max}
      && $self->{rbuf_max} < length $self->{rbuf}
   ) {
      $! = &Errno::ENOSPC; return $self->error;
   }

   return if $self->{in_drain};
   local $self->{in_drain} = 1;

   while (my $len = length $self->{rbuf}) {
      no strict 'refs';
      if (my $cb = shift @{ $self->{queue} }) {
         unless ($cb->($self)) {
            if ($self->{eof}) {
               # no progress can be made (not enough data and no data forthcoming)
               $! = &Errno::EPIPE; return $self->error;
            }

            unshift @{ $self->{queue} }, $cb;
            return;
         }
      } elsif ($self->{on_read}) {
         $self->{on_read}($self);

         if (
            $self->{eof}                    # if no further data will arrive
            && $len == length $self->{rbuf} # and no data has been consumed
            && !@{ $self->{queue} }         # and the queue is still empty
            && $self->{on_read}             # and we still want to read data
         ) {
            # then no progress can be made
            $! = &Errno::EPIPE; return $self->error;
         }
      } else {
         # read side becomes idle
         delete $self->{rw};
         return;
      }
   }

   if ($self->{eof}) {
      $self->_shutdown;
      $self->{on_eof}($self)
         if $self->{on_eof};
   }
}

=item $handle->on_read ($cb)

This replaces the currently set C<on_read> callback, or clears it (when
the new callback is C<undef>). See the description of C<on_read> in the
constructor.

=cut

sub on_read {
   my ($self, $cb) = @_;

   $self->{on_read} = $cb;
}

=item $handle->rbuf

Returns the read buffer (as a modifiable lvalue).

You can access the read buffer directly as the C<< ->{rbuf} >> member, if
you want.

NOTE: The read buffer should only be used or modified if the C<on_read>,
C<push_read> or C<unshift_read> methods are used. The other read methods
automatically manage the read buffer.

=cut

sub rbuf : lvalue {
   $_[0]{rbuf}
}

=item $handle->push_read ($cb)

=item $handle->unshift_read ($cb)

Append the given callback to the end of the queue (C<push_read>) or
prepend it (C<unshift_read>).

The callback is called each time some additional read data arrives.

It must check whether enough data is in the read buffer already.

If not enough data is available, it must return the empty list or a false
value, in which case it will be called repeatedly until enough data is
available (or an error condition is detected).

If enough data was available, then the callback must remove all data it is
interested in (which can be none at all) and return a true value. After returning
true, it will be removed from the queue.

=cut

our %RH;

sub register_read_type($$) {
   $RH{$_[0]} = $_[1];
}

sub push_read {
   my $self = shift;
   my $cb = pop;

   if (@_) {
      my $type = shift;

      $cb = ($RH{$type} or Carp::croak "unsupported type passed to AnyEvent::Handle::push_read")
            ->($self, $cb, @_);
   }

   push @{ $self->{queue} }, $cb;
   $self->_drain_rbuf;
}

sub unshift_read {
   my $self = shift;
   my $cb = pop;

   if (@_) {
      my $type = shift;

      $cb = ($RH{$type} or Carp::croak "unsupported type passed to AnyEvent::Handle::unshift_read")
            ->($self, $cb, @_);
   }


   unshift @{ $self->{queue} }, $cb;
   $self->_drain_rbuf;
}

=item $handle->push_read (type => @args, $cb)

=item $handle->unshift_read (type => @args, $cb)

Instead of providing a callback that parses the data itself you can chose
between a number of predefined parsing formats, for chunks of data, lines
etc.

Predefined types are (if you have ideas for additional types, feel free to
drop by and tell us):

=over 4

=item chunk => $octets, $cb->($self, $data)

Invoke the callback only once C<$octets> bytes have been read. Pass the
data read to the callback. The callback will never be called with less
data.

Example: read 2 bytes.

   $handle->push_read (chunk => 2, sub {
      warn "yay ", unpack "H*", $_[1];
   });

=cut

register_read_type chunk => sub {
   my ($self, $cb, $len) = @_;

   sub {
      $len <= length $_[0]{rbuf} or return;
      $cb->($_[0], substr $_[0]{rbuf}, 0, $len, "");
      1
   }
};

# compatibility with older API
sub push_read_chunk {
   $_[0]->push_read (chunk => $_[1], $_[2]);
}

sub unshift_read_chunk {
   $_[0]->unshift_read (chunk => $_[1], $_[2]);
}

=item line => [$eol, ]$cb->($self, $line, $eol)

The callback will be called only once a full line (including the end of
line marker, C<$eol>) has been read. This line (excluding the end of line
marker) will be passed to the callback as second argument (C<$line>), and
the end of line marker as the third argument (C<$eol>).

The end of line marker, C<$eol>, can be either a string, in which case it
will be interpreted as a fixed record end marker, or it can be a regex
object (e.g. created by C<qr>), in which case it is interpreted as a
regular expression.

The end of line marker argument C<$eol> is optional, if it is missing (NOT
undef), then C<qr|\015?\012|> is used (which is good for most internet
protocols).

Partial lines at the end of the stream will never be returned, as they are
not marked by the end of line marker.

=cut

register_read_type line => sub {
   my ($self, $cb, $eol) = @_;

   $eol = qr|(\015?\012)| if @_ < 3;
   $eol = quotemeta $eol unless ref $eol;
   $eol = qr|^(.*?)($eol)|s;

   sub {
      $_[0]{rbuf} =~ s/$eol// or return;

      $cb->($_[0], $1, $2);
      1
   }
};

# compatibility with older API
sub push_read_line {
   my $self = shift;
   $self->push_read (line => @_);
}

sub unshift_read_line {
   my $self = shift;
   $self->unshift_read (line => @_);
}

=item netstring => $cb->($string)

A netstring (http://cr.yp.to/proto/netstrings.txt, this is not an endorsement).

Throws an error with C<$!> set to EBADMSG on format violations.

=cut

register_read_type netstring => sub {
   my ($self, $cb) = @_;

   sub {
      unless ($_[0]{rbuf} =~ s/^(0|[1-9][0-9]*)://) {
         if ($_[0]{rbuf} =~ /[^0-9]/) {
            $! = &Errno::EBADMSG;
            $self->error;
         }
         return;
      }

      my $len = $1;

      $self->unshift_read (chunk => $len, sub {
         my $string = $_[1];
         $_[0]->unshift_read (chunk => 1, sub {
            if ($_[1] eq ",") {
               $cb->($_[0], $string);
            } else {
               $! = &Errno::EBADMSG;
               $self->error;
            }
         });
      });

      1
   }
};

=back

=item AnyEvent::Handle::register_read_type type => $coderef->($self, $cb, @args)

This function (not method) lets you add your own types to C<push_read>.

Whenever the given C<type> is used, C<push_read> will invoke the code
reference with the handle object, the callback and the remaining
arguments.

The code reference is supposed to return a callback (usually a closure)
that works as a plain read callback (see C<< ->push_read ($cb) >>).

It should invoke the passed callback when it is done reading (remember to
pass C<$self> as first argument as all other callbacks do that).

Note that this is a function, and all types registered this way will be
global, so try to use unique names.

For examples, see the source of this module (F<perldoc -m AnyEvent::Handle>,
search for C<register_read_type>)).

=item $handle->stop_read

=item $handle->start_read

In rare cases you actually do not want to read anything from the
socket. In this case you can call C<stop_read>. Neither C<on_read> no
any queued callbacks will be executed then. To start reading again, call
C<start_read>.

=cut

sub stop_read {
   my ($self) = @_;

   delete $self->{rw};
}

sub start_read {
   my ($self) = @_;

   unless ($self->{rw} || $self->{eof}) {
      Scalar::Util::weaken $self;

      $self->{rw} = AnyEvent->io (fh => $self->{fh}, poll => "r", cb => sub {
         my $rbuf = $self->{filter_r} ? \my $buf : \$self->{rbuf};
         my $len = sysread $self->{fh}, $$rbuf, $self->{read_size} || 8192, length $$rbuf;

         if ($len > 0) {
            $self->{filter_r}
               ? $self->{filter_r}->($self, $rbuf)
               : $self->_drain_rbuf;

         } elsif (defined $len) {
            delete $self->{rw};
            $self->{eof} = 1;
            $self->_drain_rbuf;

         } elsif ($! != EAGAIN && $! != EINTR && $! != &AnyEvent::Util::WSAWOULDBLOCK) {
            return $self->error;
         }
      });
   }
}

sub _dotls {
   my ($self) = @_;

   if (length $self->{tls_wbuf}) {
      while ((my $len = Net::SSLeay::write ($self->{tls}, $self->{tls_wbuf})) > 0) {
         substr $self->{tls_wbuf}, 0, $len, "";
      }
   }

   if (defined (my $buf = Net::SSLeay::BIO_read ($self->{tls_wbio}))) {
      $self->{wbuf} .= $buf;
      $self->_drain_wbuf;
   }

   while (defined (my $buf = Net::SSLeay::read ($self->{tls}))) {
      $self->{rbuf} .= $buf;
      $self->_drain_rbuf;
   }

   my $err = Net::SSLeay::get_error ($self->{tls}, -1);

   if ($err!= Net::SSLeay::ERROR_WANT_READ ()) {
      if ($err == Net::SSLeay::ERROR_SYSCALL ()) {
         $self->error;
      } elsif ($err == Net::SSLeay::ERROR_SSL ())  {
         $! = &Errno::EIO;
         $self->error;
      }

      # all others are fine for our purposes
   }
}

=item $handle->starttls ($tls[, $tls_ctx])

Instead of starting TLS negotiation immediately when the AnyEvent::Handle
object is created, you can also do that at a later time by calling
C<starttls>.

The first argument is the same as the C<tls> constructor argument (either
C<"connect">, C<"accept"> or an existing Net::SSLeay object).

The second argument is the optional C<Net::SSLeay::CTX> object that is
used when AnyEvent::Handle has to create its own TLS connection object.

=cut

# TODO: maybe document...
sub starttls {
   my ($self, $ssl, $ctx) = @_;

   $self->stoptls;

   if ($ssl eq "accept") {
      $ssl = Net::SSLeay::new ($ctx || TLS_CTX ());
      Net::SSLeay::set_accept_state ($ssl);
   } elsif ($ssl eq "connect") {
      $ssl = Net::SSLeay::new ($ctx || TLS_CTX ());
      Net::SSLeay::set_connect_state ($ssl);
   }

   $self->{tls} = $ssl;

   # basically, this is deep magic (because SSL_read should have the same issues)
   # but the openssl maintainers basically said: "trust us, it just works".
   # (unfortunately, we have to hardcode constants because the abysmally misdesigned
   # and mismaintained ssleay-module doesn't even offer them).
   # http://www.mail-archive.com/openssl-dev@openssl.org/msg22420.html
   Net::SSLeay::CTX_set_mode ($self->{tls},
      (eval { local $SIG{__DIE__}; Net::SSLeay::MODE_ENABLE_PARTIAL_WRITE () } || 1)
      | (eval { local $SIG{__DIE__}; Net::SSLeay::MODE_ACCEPT_MOVING_WRITE_BUFFER () } || 2));

   $self->{tls_rbio} = Net::SSLeay::BIO_new (Net::SSLeay::BIO_s_mem ());
   $self->{tls_wbio} = Net::SSLeay::BIO_new (Net::SSLeay::BIO_s_mem ());

   Net::SSLeay::set_bio ($ssl, $self->{tls_rbio}, $self->{tls_wbio});

   $self->{filter_w} = sub {
      $_[0]{tls_wbuf} .= ${$_[1]};
      &_dotls;
   };
   $self->{filter_r} = sub {
      Net::SSLeay::BIO_write ($_[0]{tls_rbio}, ${$_[1]});
      &_dotls;
   };
}

=item $handle->stoptls

Destroys the SSL connection, if any. Partial read or write data will be
lost.

=cut

sub stoptls {
   my ($self) = @_;

   Net::SSLeay::free (delete $self->{tls}) if $self->{tls};
   delete $self->{tls_rbio};
   delete $self->{tls_wbio};
   delete $self->{tls_wbuf};
   delete $self->{filter_r};
   delete $self->{filter_w};
}

sub DESTROY {
   my $self = shift;

   $self->stoptls;
}

=item AnyEvent::Handle::TLS_CTX

This function creates and returns the Net::SSLeay::CTX object used by
default for TLS mode.

The context is created like this:

   Net::SSLeay::load_error_strings;
   Net::SSLeay::SSLeay_add_ssl_algorithms;
   Net::SSLeay::randomize;

   my $CTX = Net::SSLeay::CTX_new;

   Net::SSLeay::CTX_set_options $CTX, Net::SSLeay::OP_ALL

=cut

our $TLS_CTX;

sub TLS_CTX() {
   $TLS_CTX || do {
      require Net::SSLeay;

      Net::SSLeay::load_error_strings ();
      Net::SSLeay::SSLeay_add_ssl_algorithms ();
      Net::SSLeay::randomize ();

      $TLS_CTX = Net::SSLeay::CTX_new ();

      Net::SSLeay::CTX_set_options ($TLS_CTX, Net::SSLeay::OP_ALL ());

      $TLS_CTX
   }
}

=back

=head1 AUTHOR

Robin Redeker C<< <elmex at ta-sa.org> >>, Marc Lehmann <schmorp@schmorp.de>.

=cut

1; # End of AnyEvent::Handle
