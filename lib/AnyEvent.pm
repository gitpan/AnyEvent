=head1 NAME

AnyEvent - provide framework for multiple event loops

EV, Event, Coro::EV, Coro::Event, Glib, Tk, Perl - various supported event loops

=head1 SYNOPSIS

   use AnyEvent;

   my $w = AnyEvent->io (fh => $fh, poll => "r|w", cb => sub {
      ...
   });

   my $w = AnyEvent->timer (after => $seconds, cb => sub {
      ...
   });

   my $w = AnyEvent->condvar; # stores whether a condition was flagged
   $w->wait; # enters "main loop" till $condvar gets ->broadcast
   $w->broadcast; # wake up current and all future wait's

=head1 WHY YOU SHOULD USE THIS MODULE (OR NOT)

Glib, POE, IO::Async, Event... CPAN offers event models by the dozen
nowadays. So what is different about AnyEvent?

Executive Summary: AnyEvent is I<compatible>, AnyEvent is I<free of
policy> and AnyEvent is I<small and efficient>.

First and foremost, I<AnyEvent is not an event model> itself, it only
interfaces to whatever event model the main program happens to use in a
pragmatic way. For event models and certain classes of immortals alike,
the statement "there can only be one" is a bitter reality: In general,
only one event loop can be active at the same time in a process. AnyEvent
helps hiding the differences between those event loops.

The goal of AnyEvent is to offer module authors the ability to do event
programming (waiting for I/O or timer events) without subscribing to a
religion, a way of living, and most importantly: without forcing your
module users into the same thing by forcing them to use the same event
model you use.

For modules like POE or IO::Async (which is a total misnomer as it is
actually doing all I/O I<synchronously>...), using them in your module is
like joining a cult: After you joined, you are dependent on them and you
cannot use anything else, as it is simply incompatible to everything that
isn't itself. What's worse, all the potential users of your module are
I<also> forced to use the same event loop you use.

AnyEvent is different: AnyEvent + POE works fine. AnyEvent + Glib works
fine. AnyEvent + Tk works fine etc. etc. but none of these work together
with the rest: POE + IO::Async? no go. Tk + Event? no go. Again: if
your module uses one of those, every user of your module has to use it,
too. But if your module uses AnyEvent, it works transparently with all
event models it supports (including stuff like POE and IO::Async, as long
as those use one of the supported event loops. It is trivial to add new
event loops to AnyEvent, too, so it is future-proof).

In addition to being free of having to use I<the one and only true event
model>, AnyEvent also is free of bloat and policy: with POE or similar
modules, you get an enourmous amount of code and strict rules you have to
follow. AnyEvent, on the other hand, is lean and up to the point, by only
offering the functionality that is necessary, in as thin as a wrapper as
technically possible.

Of course, if you want lots of policy (this can arguably be somewhat
useful) and you want to force your users to use the one and only event
model, you should I<not> use this module.


=head1 DESCRIPTION

L<AnyEvent> provides an identical interface to multiple event loops. This
allows module authors to utilise an event loop without forcing module
users to use the same event loop (as only a single event loop can coexist
peacefully at any one time).

The interface itself is vaguely similar, but not identical to the L<Event>
module.

During the first call of any watcher-creation method, the module tries
to detect the currently loaded event loop by probing whether one of the
following modules is already loaded: L<Coro::EV>, L<Coro::Event>, L<EV>,
L<Event>, L<Glib>, L<Tk>. The first one found is used. If none are found,
the module tries to load these modules in the stated order. The first one
that can be successfully loaded will be used. If, after this, still none
could be found, AnyEvent will fall back to a pure-perl event loop, which
is not very efficient, but should work everywhere.

Because AnyEvent first checks for modules that are already loaded, loading
an event model explicitly before first using AnyEvent will likely make
that model the default. For example:

   use Tk;
   use AnyEvent;

   # .. AnyEvent will likely default to Tk

The I<likely> means that, if any module loads another event model and
starts using it, all bets are off. Maybe you should tell their authors to
use AnyEvent so their modules work together with others seamlessly...

The pure-perl implementation of AnyEvent is called
C<AnyEvent::Impl::Perl>. Like other event modules you can load it
explicitly.

=head1 WATCHERS

AnyEvent has the central concept of a I<watcher>, which is an object that
stores relevant data for each kind of event you are waiting for, such as
the callback to call, the filehandle to watch, etc.

These watchers are normal Perl objects with normal Perl lifetime. After
creating a watcher it will immediately "watch" for events and invoke the
callback when the event occurs (of course, only when the event model
is in control).

To disable the watcher you have to destroy it (e.g. by setting the
variable you store it in to C<undef> or otherwise deleting all references
to it).

All watchers are created by calling a method on the C<AnyEvent> class.

Many watchers either are used with "recursion" (repeating timers for
example), or need to refer to their watcher object in other ways.

An any way to achieve that is this pattern:

  my $w; $w = AnyEvent->type (arg => value ..., cb => sub {
     # you can use $w here, for example to undef it
     undef $w;
  });

Note that C<my $w; $w => combination. This is necessary because in Perl,
my variables are only visible after the statement in which they are
declared.

=head2 IO WATCHERS

You can create an I/O watcher by calling the C<< AnyEvent->io >> method
with the following mandatory key-value pairs as arguments:

C<fh> the Perl I<file handle> (I<not> file descriptor) to watch for
events. C<poll> must be a string that is either C<r> or C<w>, which
creates a watcher waiting for "r"eadable or "w"ritable events,
respectively. C<cb> is the callback to invoke each time the file handle
becomes ready.

File handles will be kept alive, so as long as the watcher exists, the
file handle exists, too.

It is not allowed to close a file handle as long as any watcher is active
on the underlying file descriptor.

Some event loops issue spurious readyness notifications, so you should
always use non-blocking calls when reading/writing from/to your file
handles.

Example:

   # wait for readability of STDIN, then read a line and disable the watcher
   my $w; $w = AnyEvent->io (fh => \*STDIN, poll => 'r', cb => sub {
      chomp (my $input = <STDIN>);
      warn "read: $input\n";
      undef $w;
   });

=head2 TIME WATCHERS

You can create a time watcher by calling the C<< AnyEvent->timer >>
method with the following mandatory arguments:

C<after> specifies after how many seconds (fractional values are
supported) should the timer activate. C<cb> the callback to invoke in that
case.

The timer callback will be invoked at most once: if you want a repeating
timer you have to create a new watcher (this is a limitation by both Tk
and Glib).

Example:

   # fire an event after 7.7 seconds
   my $w = AnyEvent->timer (after => 7.7, cb => sub {
      warn "timeout\n";
   });

   # to cancel the timer:
   undef $w;

Example 2:

   # fire an event after 0.5 seconds, then roughly every second
   my $w;

   my $cb = sub {
      # cancel the old timer while creating a new one
      $w = AnyEvent->timer (after => 1, cb => $cb);
   };

   # start the "loop" by creating the first watcher
   $w = AnyEvent->timer (after => 0.5, cb => $cb);

=head3 TIMING ISSUES

There are two ways to handle timers: based on real time (relative, "fire
in 10 seconds") and based on wallclock time (absolute, "fire at 12
o'clock").

While most event loops expect timers to specified in a relative way, they use
absolute time internally. This makes a difference when your clock "jumps",
for example, when ntp decides to set your clock backwards from the wrong 2014-01-01 to
2008-01-01, a watcher that you created to fire "after" a second might actually take
six years to finally fire.

AnyEvent cannot compensate for this. The only event loop that is conscious
about these issues is L<EV>, which offers both relative (ev_timer) and
absolute (ev_periodic) timers.

AnyEvent always prefers relative timers, if available, matching the
AnyEvent API.

=head2 SIGNAL WATCHERS

You can watch for signals using a signal watcher, C<signal> is the signal
I<name> without any C<SIG> prefix, C<cb> is the Perl callback to
be invoked whenever a signal occurs.

Multiple signals occurances can be clumped together into one callback
invocation, and callback invocation will be synchronous. synchronous means
that it might take a while until the signal gets handled by the process,
but it is guarenteed not to interrupt any other callbacks.

The main advantage of using these watchers is that you can share a signal
between multiple watchers.

This watcher might use C<%SIG>, so programs overwriting those signals
directly will likely not work correctly.

Example: exit on SIGINT

   my $w = AnyEvent->signal (signal => "INT", cb => sub { exit 1 });

=head2 CHILD PROCESS WATCHERS

You can also watch on a child process exit and catch its exit status.

The child process is specified by the C<pid> argument (if set to C<0>, it
watches for any child process exit). The watcher will trigger as often
as status change for the child are received. This works by installing a
signal handler for C<SIGCHLD>. The callback will be called with the pid
and exit status (as returned by waitpid).

Example: wait for pid 1333

  my $w = AnyEvent->child (
     pid => 1333,
     cb  => sub {
        my ($pid, $status) = @_;
        warn "pid $pid exited with status $status";
     },
  );

=head2 CONDITION VARIABLES

Condition variables can be created by calling the C<< AnyEvent->condvar >>
method without any arguments.

A condition variable waits for a condition - precisely that the C<<
->broadcast >> method has been called.

They are very useful to signal that a condition has been fulfilled, for
example, if you write a module that does asynchronous http requests,
then a condition variable would be the ideal candidate to signal the
availability of results.

You can also use condition variables to block your main program until
an event occurs - for example, you could C<< ->wait >> in your main
program until the user clicks the Quit button in your app, which would C<<
->broadcast >> the "quit" event.

Note that condition variables recurse into the event loop - if you have
two pirces of code that call C<< ->wait >> in a round-robbin fashion, you
lose. Therefore, condition variables are good to export to your caller, but
you should avoid making a blocking wait yourself, at least in callbacks,
as this asks for trouble.

This object has two methods:

=over 4

=item $cv->wait

Wait (blocking if necessary) until the C<< ->broadcast >> method has been
called on c<$cv>, while servicing other watchers normally.

You can only wait once on a condition - additional calls will return
immediately.

Not all event models support a blocking wait - some die in that case
(programs might want to do that to stay interactive), so I<if you are
using this from a module, never require a blocking wait>, but let the
caller decide whether the call will block or not (for example, by coupling
condition variables with some kind of request results and supporting
callbacks so the caller knows that getting the result will not block,
while still suppporting blocking waits if the caller so desires).

Another reason I<never> to C<< ->wait >> in a module is that you cannot
sensibly have two C<< ->wait >>'s in parallel, as that would require
multiple interpreters or coroutines/threads, none of which C<AnyEvent>
can supply (the coroutine-aware backends L<AnyEvent::Impl::CoroEV> and
L<AnyEvent::Impl::CoroEvent> explicitly support concurrent C<< ->wait >>'s
from different coroutines, however).

=item $cv->broadcast

Flag the condition as ready - a running C<< ->wait >> and all further
calls to C<wait> will (eventually) return after this method has been
called. If nobody is waiting the broadcast will be remembered..

=back

Example:

   # wait till the result is ready
   my $result_ready = AnyEvent->condvar;

   # do something such as adding a timer
   # or socket watcher the calls $result_ready->broadcast
   # when the "result" is ready.
   # in this case, we simply use a timer:
   my $w = AnyEvent->timer (
      after => 1,
      cb    => sub { $result_ready->broadcast },
   );

   # this "blocks" (while handling events) till the watcher
   # calls broadcast
   $result_ready->wait;

=head1 GLOBAL VARIABLES AND FUNCTIONS

=over 4

=item $AnyEvent::MODEL

Contains C<undef> until the first watcher is being created. Then it
contains the event model that is being used, which is the name of the
Perl class implementing the model. This class is usually one of the
C<AnyEvent::Impl:xxx> modules, but can be any other class in the case
AnyEvent has been extended at runtime (e.g. in I<rxvt-unicode>).

The known classes so far are:

   AnyEvent::Impl::CoroEV    based on Coro::EV, best choice.
   AnyEvent::Impl::CoroEvent based on Coro::Event, second best choice.
   AnyEvent::Impl::EV        based on EV (an interface to libev, also best choice).
   AnyEvent::Impl::Event     based on Event, also second best choice :)
   AnyEvent::Impl::Glib      based on Glib, third-best choice.
   AnyEvent::Impl::Tk        based on Tk, very bad choice.
   AnyEvent::Impl::Perl      pure-perl implementation, inefficient but portable.

=item AnyEvent::detect

Returns C<$AnyEvent::MODEL>, forcing autodetection of the event model
if necessary. You should only call this function right before you would
have created an AnyEvent watcher anyway, that is, as late as possible at
runtime.

=back

=head1 WHAT TO DO IN A MODULE

As a module author, you should C<use AnyEvent> and call AnyEvent methods
freely, but you should not load a specific event module or rely on it.

Be careful when you create watchers in the module body - AnyEvent will
decide which event module to use as soon as the first method is called, so
by calling AnyEvent in your module body you force the user of your module
to load the event module first.

Never call C<< ->wait >> on a condition variable unless you I<know> that
the C<< ->broadcast >> method has been called on it already. This is
because it will stall the whole program, and the whole point of using
events is to stay interactive.

It is fine, however, to call C<< ->wait >> when the user of your module
requests it (i.e. if you create a http request object ad have a method
called C<results> that returns the results, it should call C<< ->wait >>
freely, as the user of your module knows what she is doing. always).

=head1 WHAT TO DO IN THE MAIN PROGRAM

There will always be a single main program - the only place that should
dictate which event model to use.

If it doesn't care, it can just "use AnyEvent" and use it itself, or not
do anything special (it does not need to be event-based) and let AnyEvent
decide which implementation to chose if some module relies on it.

If the main program relies on a specific event model. For example, in
Gtk2 programs you have to rely on the Glib module. You should load the
event module before loading AnyEvent or any module that uses it: generally
speaking, you should load it as early as possible. The reason is that
modules might create watchers when they are loaded, and AnyEvent will
decide on the event model to use as soon as it creates watchers, and it
might chose the wrong one unless you load the correct one yourself.

You can chose to use a rather inefficient pure-perl implementation by
loading the C<AnyEvent::Impl::Perl> module, which gives you similar
behaviour everywhere, but letting AnyEvent chose is generally better.

=cut

package AnyEvent;

no warnings;
use strict;

use Carp;

our $VERSION = '3.11';
our $MODEL;

our $AUTOLOAD;
our @ISA;

our $verbose = $ENV{PERL_ANYEVENT_VERBOSE}*1;

our @REGISTRY;

my @models = (
   [Coro::EV::             => AnyEvent::Impl::CoroEV::],
   [Coro::Event::          => AnyEvent::Impl::CoroEvent::],
   [EV::                   => AnyEvent::Impl::EV::],
   [Event::                => AnyEvent::Impl::Event::],
   [Glib::                 => AnyEvent::Impl::Glib::],
   [Tk::                   => AnyEvent::Impl::Tk::],
   [AnyEvent::Impl::Perl:: => AnyEvent::Impl::Perl::],
);

our %method = map +($_ => 1), qw(io timer condvar broadcast wait signal one_event DESTROY);

sub detect() {
   unless ($MODEL) {
      no strict 'refs';

      # check for already loaded models
      for (@REGISTRY, @models) {
         my ($package, $model) = @$_;
         if (${"$package\::VERSION"} > 0) {
            if (eval "require $model") {
               $MODEL = $model;
               warn "AnyEvent: found model '$model', using it.\n" if $verbose > 1;
               last;
            }
         }
      }

      unless ($MODEL) {
         # try to load a model

         for (@REGISTRY, @models) {
            my ($package, $model) = @$_;
            if (eval "require $package"
                and ${"$package\::VERSION"} > 0
                and eval "require $model") {
               $MODEL = $model;
               warn "AnyEvent: autoprobed and loaded model '$model', using it.\n" if $verbose > 1;
               last;
            }
         }

         $MODEL
           or die "No event module selected for AnyEvent and autodetect failed. Install any one of these modules: EV (or Coro+EV), Event (or Coro+Event), Glib or Tk.";
      }

      unshift @ISA, $MODEL;
      push @{"$MODEL\::ISA"}, "AnyEvent::Base";
   }

   $MODEL
}

sub AUTOLOAD {
   (my $func = $AUTOLOAD) =~ s/.*://;

   $method{$func}
      or croak "$func: not a valid method for AnyEvent objects";

   detect unless $MODEL;

   my $class = shift;
   $class->$func (@_);
}

package AnyEvent::Base;

# default implementation for ->condvar, ->wait, ->broadcast

sub condvar {
   bless \my $flag, "AnyEvent::Base::CondVar"
}

sub AnyEvent::Base::CondVar::broadcast {
   ${$_[0]}++;
}

sub AnyEvent::Base::CondVar::wait {
   AnyEvent->one_event while !${$_[0]};
}

# default implementation for ->signal

our %SIG_CB;

sub signal {
   my (undef, %arg) = @_;

   my $signal = uc $arg{signal}
      or Carp::croak "required option 'signal' is missing";

   $SIG_CB{$signal}{$arg{cb}} = $arg{cb};
   $SIG{$signal} ||= sub {
      $_->() for values %{ $SIG_CB{$signal} || {} };
   };

   bless [$signal, $arg{cb}], "AnyEvent::Base::Signal"
}

sub AnyEvent::Base::Signal::DESTROY {
   my ($signal, $cb) = @{$_[0]};

   delete $SIG_CB{$signal}{$cb};

   $SIG{$signal} = 'DEFAULT' unless keys %{ $SIG_CB{$signal} };
}

# default implementation for ->child

our %PID_CB;
our $CHLD_W;
our $CHLD_DELAY_W;
our $PID_IDLE;
our $WNOHANG;

sub _child_wait {
   while (0 < (my $pid = waitpid -1, $WNOHANG)) {
      $_->($pid, $?) for (values %{ $PID_CB{$pid} || {} }),
                         (values %{ $PID_CB{0}    || {} });
   }

   undef $PID_IDLE;
}

sub _sigchld {
   # make sure we deliver these changes "synchronous" with the event loop.
   $CHLD_DELAY_W ||= AnyEvent->timer (after => 0, cb => sub {
      undef $CHLD_DELAY_W;
      &_child_wait;
   });
}

sub child {
   my (undef, %arg) = @_;

   defined (my $pid = $arg{pid} + 0)
      or Carp::croak "required option 'pid' is missing";

   $PID_CB{$pid}{$arg{cb}} = $arg{cb};

   unless ($WNOHANG) {
      $WNOHANG = eval { require POSIX; &POSIX::WNOHANG } || 1;
   }

   unless ($CHLD_W) {
      $CHLD_W = AnyEvent->signal (signal => 'CHLD', cb => \&_sigchld);
      # child could be a zombie already, so make at least one round
      &_sigchld;
   }

   bless [$pid, $arg{cb}], "AnyEvent::Base::Child"
}

sub AnyEvent::Base::Child::DESTROY {
   my ($pid, $cb) = @{$_[0]};

   delete $PID_CB{$pid}{$cb};
   delete $PID_CB{$pid} unless keys %{ $PID_CB{$pid} };

   undef $CHLD_W unless keys %PID_CB;
}

=head1 SUPPLYING YOUR OWN EVENT MODEL INTERFACE

This is an advanced topic that you do not normally need to use AnyEvent in
a module. This section is only of use to event loop authors who want to
provide AnyEvent compatibility.

If you need to support another event library which isn't directly
supported by AnyEvent, you can supply your own interface to it by
pushing, before the first watcher gets created, the package name of
the event module and the package name of the interface to use onto
C<@AnyEvent::REGISTRY>. You can do that before and even without loading
AnyEvent, so it is reasonably cheap.

Example:

   push @AnyEvent::REGISTRY, [urxvt => urxvt::anyevent::];

This tells AnyEvent to (literally) use the C<urxvt::anyevent::>
package/class when it finds the C<urxvt> package/module is already loaded.

When AnyEvent is loaded and asked to find a suitable event model, it
will first check for the presence of urxvt by trying to C<use> the
C<urxvt::anyevent> module.

The class should provide implementations for all watcher types. See
L<AnyEvent::Impl::EV> (source code), L<AnyEvent::Impl::Glib> (Source code)
and so on for actual examples. Use C<perldoc -m AnyEvent::Impl::Glib> to
see the sources.

If you don't provide C<signal> and C<child> watchers than AnyEvent will
provide suitable (hopefully) replacements.

The above example isn't fictitious, the I<rxvt-unicode> (a.k.a. urxvt)
terminal emulator uses the above line as-is. An interface isn't included
in AnyEvent because it doesn't make sense outside the embedded interpreter
inside I<rxvt-unicode>, and it is updated and maintained as part of the
I<rxvt-unicode> distribution.

I<rxvt-unicode> also cheats a bit by not providing blocking access to
condition variables: code blocking while waiting for a condition will
C<die>. This still works with most modules/usages, and blocking calls must
not be done in an interactive application, so it makes sense.

=head1 ENVIRONMENT VARIABLES

The following environment variables are used by this module:

C<PERL_ANYEVENT_VERBOSE> when set to C<2> or higher, cause AnyEvent to
report to STDERR which event model it chooses.

=head1 EXAMPLE PROGRAM

The following program uses an IO watcher to read data from STDIN, a timer
to display a message once per second, and a condition variable to quit the
program when the user enters quit:

   use AnyEvent;

   my $cv = AnyEvent->condvar;

   my $io_watcher = AnyEvent->io (
      fh   => \*STDIN,
      poll => 'r',
      cb   => sub {
         warn "io event <$_[0]>\n";   # will always output <r>
         chomp (my $input = <STDIN>); # read a line
         warn "read: $input\n";       # output what has been read
         $cv->broadcast if $input =~ /^q/i; # quit program if /^q/i
      },
   );

   my $time_watcher; # can only be used once

   sub new_timer {
      $timer = AnyEvent->timer (after => 1, cb => sub {
         warn "timeout\n"; # print 'timeout' about every second
         &new_timer; # and restart the time
      });
   }

   new_timer; # create first timer

   $cv->wait; # wait until user enters /^q/i

=head1 REAL-WORLD EXAMPLE

Consider the L<Net::FCP> module. It features (among others) the following
API calls, which are to freenet what HTTP GET requests are to http:

   my $data = $fcp->client_get ($url); # blocks

   my $transaction = $fcp->txn_client_get ($url); # does not block
   $transaction->cb ( sub { ... } ); # set optional result callback
   my $data = $transaction->result; # possibly blocks

The C<client_get> method works like C<LWP::Simple::get>: it requests the
given URL and waits till the data has arrived. It is defined to be:

   sub client_get { $_[0]->txn_client_get ($_[1])->result }

And in fact is automatically generated. This is the blocking API of
L<Net::FCP>, and it works as simple as in any other, similar, module.

More complicated is C<txn_client_get>: It only creates a transaction
(completion, result, ...) object and initiates the transaction.

   my $txn = bless { }, Net::FCP::Txn::;

It also creates a condition variable that is used to signal the completion
of the request:

   $txn->{finished} = AnyAvent->condvar;

It then creates a socket in non-blocking mode.

   socket $txn->{fh}, ...;
   fcntl $txn->{fh}, F_SETFL, O_NONBLOCK;
   connect $txn->{fh}, ...
      and !$!{EWOULDBLOCK}
      and !$!{EINPROGRESS}
      and Carp::croak "unable to connect: $!\n";

Then it creates a write-watcher which gets called whenever an error occurs
or the connection succeeds:

   $txn->{w} = AnyEvent->io (fh => $txn->{fh}, poll => 'w', cb => sub { $txn->fh_ready_w });

And returns this transaction object. The C<fh_ready_w> callback gets
called as soon as the event loop detects that the socket is ready for
writing.

The C<fh_ready_w> method makes the socket blocking again, writes the
request data and replaces the watcher by a read watcher (waiting for reply
data). The actual code is more complicated, but that doesn't matter for
this example:

   fcntl $txn->{fh}, F_SETFL, 0;
   syswrite $txn->{fh}, $txn->{request}
      or die "connection or write error";
   $txn->{w} = AnyEvent->io (fh => $txn->{fh}, poll => 'r', cb => sub { $txn->fh_ready_r });

Again, C<fh_ready_r> waits till all data has arrived, and then stores the
result and signals any possible waiters that the request ahs finished:

   sysread $txn->{fh}, $txn->{buf}, length $txn->{$buf};

   if (end-of-file or data complete) {
     $txn->{result} = $txn->{buf};
     $txn->{finished}->broadcast;
     $txb->{cb}->($txn) of $txn->{cb}; # also call callback
   }

The C<result> method, finally, just waits for the finished signal (if the
request was already finished, it doesn't wait, of course, and returns the
data:

   $txn->{finished}->wait;
   return $txn->{result};

The actual code goes further and collects all errors (C<die>s, exceptions)
that occured during request processing. The C<result> method detects
whether an exception as thrown (it is stored inside the $txn object)
and just throws the exception, which means connection errors and other
problems get reported tot he code that tries to use the result, not in a
random callback.

All of this enables the following usage styles:

1. Blocking:

   my $data = $fcp->client_get ($url);

2. Blocking, but running in parallel:

   my @datas = map $_->result,
                  map $fcp->txn_client_get ($_),
                     @urls;

Both blocking examples work without the module user having to know
anything about events.

3a. Event-based in a main program, using any supported event module:

   use EV;

   $fcp->txn_client_get ($url)->cb (sub {
      my $txn = shift;
      my $data = $txn->result;
      ...
   });

   EV::loop;

3b. The module user could use AnyEvent, too:

   use AnyEvent;

   my $quit = AnyEvent->condvar;

   $fcp->txn_client_get ($url)->cb (sub {
      ...
      $quit->broadcast;
   });

   $quit->wait;

=head1 SEE ALSO

Event modules: L<Coro::EV>, L<EV>, L<EV::Glib>, L<Glib::EV>,
L<Coro::Event>, L<Event>, L<Glib::Event>, L<Glib>, L<Coro>, L<Tk>.

Implementations: L<AnyEvent::Impl::CoroEV>, L<AnyEvent::Impl::EV>,
L<AnyEvent::Impl::CoroEvent>, L<AnyEvent::Impl::Event>,
L<AnyEvent::Impl::Glib>, L<AnyEvent::Impl::Tk>, L<AnyEvent::Impl::Perl>.

Nontrivial usage examples: L<Net::FCP>, L<Net::XMPP2>.

=head1

=cut

1

