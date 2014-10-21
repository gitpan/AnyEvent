=head1 NAME

AnyEvent - provide framework for multiple event loops

EV, Event, Coro::EV, Coro::Event, Glib, Tk, Perl, Event::Lib, Qt, POE - various supported event loops

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
L<Event>, L<Glib>, L<AnyEvent::Impl::Perl>, L<Tk>, L<Event::Lib>, L<Qt>,
L<POE>. The first one found is used. If none are found, the module tries
to load these modules (excluding Tk, Event::Lib, Qt and POE as the pure perl
adaptor should always succeed) in the order given. The first one that can
be successfully loaded will be used. If, after this, still none could be
found, AnyEvent will fall back to a pure-perl event loop, which is not
very efficient, but should work everywhere.

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

=head2 I/O WATCHERS

You can create an I/O watcher by calling the C<< AnyEvent->io >> method
with the following mandatory key-value pairs as arguments:

C<fh> the Perl I<file handle> (I<not> file descriptor) to watch
for events. C<poll> must be a string that is either C<r> or C<w>,
which creates a watcher waiting for "r"eadable or "w"ritable events,
respectively. C<cb> is the callback to invoke each time the file handle
becomes ready.

Although the callback might get passed parameters, their value and
presence is undefined and you cannot rely on them. Portable AnyEvent
callbacks cannot use arguments passed to I/O watcher callbacks.

The I/O watcher might use the underlying file descriptor or a copy of it.
You must not close a file handle as long as any watcher is active on the
underlying file descriptor.

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
supported) the callback should be invoked. C<cb> is the callback to invoke
in that case.

Although the callback might get passed parameters, their value and
presence is undefined and you cannot rely on them. Portable AnyEvent
callbacks cannot use arguments passed to time watcher callbacks.

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

While most event loops expect timers to specified in a relative way, they
use absolute time internally. This makes a difference when your clock
"jumps", for example, when ntp decides to set your clock backwards from
the wrong date of 2014-01-01 to 2008-01-01, a watcher that is supposed to
fire "after" a second might actually take six years to finally fire.

AnyEvent cannot compensate for this. The only event loop that is conscious
about these issues is L<EV>, which offers both relative (ev_timer, based
on true relative time) and absolute (ev_periodic, based on wallclock time)
timers.

AnyEvent always prefers relative timers, if available, matching the
AnyEvent API.

=head2 SIGNAL WATCHERS

You can watch for signals using a signal watcher, C<signal> is the signal
I<name> without any C<SIG> prefix, C<cb> is the Perl callback to
be invoked whenever a signal occurs.

Although the callback might get passed parameters, their value and
presence is undefined and you cannot rely on them. Portable AnyEvent
callbacks cannot use arguments passed to signal watcher callbacks.

Multiple signal occurances can be clumped together into one callback
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
and exit status (as returned by waitpid), so unlike other watcher types,
you I<can> rely on child watcher callback arguments.

There is a slight catch to child watchers, however: you usually start them
I<after> the child process was created, and this means the process could
have exited already (and no SIGCHLD will be sent anymore).

Not all event models handle this correctly (POE doesn't), but even for
event models that I<do> handle this correctly, they usually need to be
loaded before the process exits (i.e. before you fork in the first place).

This means you cannot create a child watcher as the very first thing in an
AnyEvent program, you I<have> to create at least one watcher before you
C<fork> the child (alternatively, you can call C<AnyEvent::detect>).

Example: fork a process and wait for it

  my $done = AnyEvent->condvar;

  AnyEvent::detect; # force event module to be initialised

  my $pid = fork or exit 5;

  my $w = AnyEvent->child (
     pid => $pid,
     cb  => sub {
        my ($pid, $status) = @_;
        warn "pid $pid exited with status $status";
        $done->broadcast;
     },
  );

  # do something else, then wait for process exit
  $done->wait;

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
   AnyEvent::Impl::EV        based on EV (an interface to libev, best choice).
   AnyEvent::Impl::Event     based on Event, second best choice.
   AnyEvent::Impl::Glib      based on Glib, third-best choice.
   AnyEvent::Impl::Perl      pure-perl implementation, inefficient but portable.
   AnyEvent::Impl::Tk        based on Tk, very bad choice.
   AnyEvent::Impl::Qt        based on Qt, cannot be autoprobed (see its docs).
   AnyEvent::Impl::EventLib  based on Event::Lib, leaks memory and worse.
   AnyEvent::Impl::POE       based on POE, not generic enough for full support.

There is no support for WxWidgets, as WxWidgets has no support for
watching file handles. However, you can use WxWidgets through the
POE Adaptor, as POE has a Wx backend that simply polls 20 times per
second, which was considered to be too horrible to even consider for
AnyEvent. Likewise, other POE backends can be used by AnyEvent by using
it's adaptor.

AnyEvent knows about L<Prima> and L<Wx> and will try to use L<POE> when
autodetecting them.

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

=head1 OTHER MODULES

The following is a non-exhaustive list of additional modules that use
AnyEvent and can therefore be mixed easily with other AnyEvent modules
in the same program. Some of the modules come with AnyEvent, some are
available via CPAN.

=over 4

=item L<AnyEvent::Util>

Contains various utility functions that replace often-used but blocking
functions such as C<inet_aton> by event-/callback-based versions.

=item L<AnyEvent::Handle>

Provide read and write buffers and manages watchers for reads and writes.

=item L<AnyEvent::Socket>

Provides a means to do non-blocking connects, accepts etc.

=item L<AnyEvent::HTTPD>

Provides a simple web application server framework.

=item L<AnyEvent::DNS>

Provides asynchronous DNS resolver capabilities, beyond what
L<AnyEvent::Util> offers.

=item L<AnyEvent::FastPing>

The fastest ping in the west.

=item L<Net::IRC3>

AnyEvent based IRC client module family.

=item L<Net::XMPP2>

AnyEvent based XMPP (Jabber protocol) module family.

=item L<Net::FCP>

AnyEvent-based implementation of the Freenet Client Protocol, birthplace
of AnyEvent.

=item L<Event::ExecFlow>

High level API for event-based execution flow control.

=item L<Coro>

Has special support for AnyEvent.

=item L<IO::Lambda>

The lambda approach to I/O - don't ask, look there. Can use AnyEvent.

=item L<IO::AIO>

Truly asynchronous I/O, should be in the toolbox of every event
programmer. Can be trivially made to use AnyEvent.

=item L<BDB>

Truly asynchronous Berkeley DB access. Can be trivially made to use
AnyEvent.

=back

=cut

package AnyEvent;

no warnings;
use strict;

use Carp;

our $VERSION = '3.3';
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
   [Wx::                   => AnyEvent::Impl::POE::],
   [Prima::                => AnyEvent::Impl::POE::],
   [AnyEvent::Impl::Perl:: => AnyEvent::Impl::Perl::],
   # everything below here will not be autoprobed as the pureperl backend should work everywhere
   [Event::Lib::           => AnyEvent::Impl::EventLib::], # too buggy
   [Qt::                   => AnyEvent::Impl::Qt::],       # requires special main program
   [POE::Kernel::          => AnyEvent::Impl::POE::],      # lasciate ogni speranza
);

our %method = map +($_ => 1), qw(io timer signal child condvar broadcast wait one_event DESTROY);

sub detect() {
   unless ($MODEL) {
      no strict 'refs';

      if ($ENV{PERL_ANYEVENT_MODEL} =~ /^([a-zA-Z]+)$/) {
         my $model = "AnyEvent::Impl::$1";
         if (eval "require $model") {
            $MODEL = $model;
            warn "AnyEvent: loaded model '$model' (forced by \$PERL_ANYEVENT_MODEL), using it.\n" if $verbose > 1;
         } else {
            warn "AnyEvent: unable to load model '$model' (from \$PERL_ANYEVENT_MODEL):\n$@" if $verbose;
         }
      }

      # check for already loaded models
      unless ($MODEL) {
         for (@REGISTRY, @models) {
            my ($package, $model) = @$_;
            if (${"$package\::VERSION"} > 0) {
               if (eval "require $model") {
                  $MODEL = $model;
                  warn "AnyEvent: autodetected model '$model', using it.\n" if $verbose > 1;
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
                  warn "AnyEvent: autoprobed model '$model', using it.\n" if $verbose > 1;
                  last;
               }
            }

            $MODEL
              or die "No event module selected for AnyEvent and autodetect failed. Install any one of these modules: EV (or Coro+EV), Event (or Coro+Event) or Glib.";
         }
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

=over 4

=item C<PERL_ANYEVENT_VERBOSE>

By default, AnyEvent will be completely silent except in fatal
conditions. You can set this environment variable to make AnyEvent more
talkative.

When set to C<1> or higher, causes AnyEvent to warn about unexpected
conditions, such as not being able to load the event model specified by
C<PERL_ANYEVENT_MODEL>.

When set to C<2> or higher, cause AnyEvent to report to STDERR which event
model it chooses.

=item C<PERL_ANYEVENT_MODEL>

This can be used to specify the event model to be used by AnyEvent, before
autodetection and -probing kicks in. It must be a string consisting
entirely of ASCII letters. The string C<AnyEvent::Impl::> gets prepended
and the resulting module name is loaded and if the load was successful,
used as event model. If it fails to load AnyEvent will proceed with
autodetection and -probing.

This functionality might change in future versions.

For example, to force the pure perl model (L<AnyEvent::Impl::Perl>) you
could start your program like this:

  PERL_ANYEVENT_MODEL=Perl perl ...

=back

=head1 EXAMPLE PROGRAM

The following program uses an I/O watcher to read data from STDIN, a timer
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


=head1 BENCHMARKS

To give you an idea of the performance and overheads that AnyEvent adds
over the event loops themselves and to give you an impression of the speed
of various event loops I prepared some benchmarks.

=head2 BENCHMARKING ANYEVENT OVERHEAD

Here is a benchmark of various supported event models used natively and
through anyevent. The benchmark creates a lot of timers (with a zero
timeout) and I/O watchers (watching STDOUT, a pty, to become writable,
which it is), lets them fire exactly once and destroys them again.

Source code for this benchmark is found as F<eg/bench> in the AnyEvent
distribution.

=head3 Explanation of the columns

I<watcher> is the number of event watchers created/destroyed. Since
different event models feature vastly different performances, each event
loop was given a number of watchers so that overall runtime is acceptable
and similar between tested event loop (and keep them from crashing): Glib
would probably take thousands of years if asked to process the same number
of watchers as EV in this benchmark.

I<bytes> is the number of bytes (as measured by the resident set size,
RSS) consumed by each watcher. This method of measuring captures both C
and Perl-based overheads.

I<create> is the time, in microseconds (millionths of seconds), that it
takes to create a single watcher. The callback is a closure shared between
all watchers, to avoid adding memory overhead. That means closure creation
and memory usage is not included in the figures.

I<invoke> is the time, in microseconds, used to invoke a simple
callback. The callback simply counts down a Perl variable and after it was
invoked "watcher" times, it would C<< ->broadcast >> a condvar once to
signal the end of this phase.

I<destroy> is the time, in microseconds, that it takes to destroy a single
watcher.

=head3 Results

          name watchers bytes create invoke destroy comment
         EV/EV   400000   244   0.56   0.46    0.31 EV native interface
        EV/Any   100000   244   2.50   0.46    0.29 EV + AnyEvent watchers
    CoroEV/Any   100000   244   2.49   0.44    0.29 coroutines + Coro::Signal
      Perl/Any   100000   513   4.92   0.87    1.12 pure perl implementation
   Event/Event    16000   516  31.88  31.30    0.85 Event native interface
     Event/Any    16000   590  35.75  31.42    1.08 Event + AnyEvent watchers
      Glib/Any    16000  1357  98.22  12.41   54.00 quadratic behaviour
        Tk/Any     2000  1860  26.97  67.98   14.00 SEGV with >> 2000 watchers
     POE/Event     2000  6644 108.64 736.02   14.73 via POE::Loop::Event
    POE/Select     2000  6343  94.13 809.12  565.96 via POE::Loop::Select

=head3 Discussion

The benchmark does I<not> measure scalability of the event loop very
well. For example, a select-based event loop (such as the pure perl one)
can never compete with an event loop that uses epoll when the number of
file descriptors grows high. In this benchmark, all events become ready at
the same time, so select/poll-based implementations get an unnatural speed
boost.

Also, note that the number of watchers usually has a nonlinear effect on
overall speed, that is, creating twice as many watchers doesn't take twice
the time - usually it takes longer. This puts event loops tested with a
higher number of watchers at a disadvantage.

To put the range of results into perspective, consider that on the
benchmark machine, handling an event takes roughly 1600 CPU cycles with
EV, 3100 CPU cycles with AnyEvent's pure perl loop and almost 3000000 CPU
cycles with POE.

C<EV> is the sole leader regarding speed and memory use, which are both
maximal/minimal, respectively. Even when going through AnyEvent, it uses
far less memory than any other event loop and is still faster than Event
natively.

The pure perl implementation is hit in a few sweet spots (both the
constant timeout and the use of a single fd hit optimisations in the perl
interpreter and the backend itself). Nevertheless this shows that it
adds very little overhead in itself. Like any select-based backend its
performance becomes really bad with lots of file descriptors (and few of
them active), of course, but this was not subject of this benchmark.

The C<Event> module has a relatively high setup and callback invocation
cost, but overall scores in on the third place.

C<Glib>'s memory usage is quite a bit higher, but it features a
faster callback invocation and overall ends up in the same class as
C<Event>. However, Glib scales extremely badly, doubling the number of
watchers increases the processing time by more than a factor of four,
making it completely unusable when using larger numbers of watchers
(note that only a single file descriptor was used in the benchmark, so
inefficiencies of C<poll> do not account for this).

The C<Tk> adaptor works relatively well. The fact that it crashes with
more than 2000 watchers is a big setback, however, as correctness takes
precedence over speed. Nevertheless, its performance is surprising, as the
file descriptor is dup()ed for each watcher. This shows that the dup()
employed by some adaptors is not a big performance issue (it does incur a
hidden memory cost inside the kernel which is not reflected in the figures
above).

C<POE>, regardless of underlying event loop (whether using its pure
perl select-based backend or the Event module, the POE-EV backend
couldn't be tested because it wasn't working) shows abysmal performance
and memory usage: Watchers use almost 30 times as much memory as
EV watchers, and 10 times as much memory as Event (the high memory
requirements are caused by requiring a session for each watcher). Watcher
invocation speed is almost 900 times slower than with AnyEvent's pure perl
implementation. The design of the POE adaptor class in AnyEvent can not
really account for this, as session creation overhead is small compared
to execution of the state machine, which is coded pretty optimally within
L<AnyEvent::Impl::POE>. POE simply seems to be abysmally slow.

=head3 Summary

=over 4

=item * Using EV through AnyEvent is faster than any other event loop
(even when used without AnyEvent), but most event loops have acceptable
performance with or without AnyEvent.

=item * The overhead AnyEvent adds is usually much smaller than the overhead of
the actual event loop, only with extremely fast event loops such as EV
adds AnyEvent significant overhead.

=item * You should avoid POE like the plague if you want performance or
reasonable memory usage.

=back

=head2 BENCHMARKING THE LARGE SERVER CASE

This benchmark atcually benchmarks the event loop itself. It works by
creating a number of "servers": each server consists of a socketpair, a
timeout watcher that gets reset on activity (but never fires), and an I/O
watcher waiting for input on one side of the socket. Each time the socket
watcher reads a byte it will write that byte to a random other "server".

The effect is that there will be a lot of I/O watchers, only part of which
are active at any one point (so there is a constant number of active
fds for each loop iterstaion, but which fds these are is random). The
timeout is reset each time something is read because that reflects how
most timeouts work (and puts extra pressure on the event loops).

In this benchmark, we use 10000 socketpairs (20000 sockets), of which 100
(1%) are active. This mirrors the activity of large servers with many
connections, most of which are idle at any one point in time.

Source code for this benchmark is found as F<eg/bench2> in the AnyEvent
distribution.

=head3 Explanation of the columns

I<sockets> is the number of sockets, and twice the number of "servers" (as
each server has a read and write socket end).

I<create> is the time it takes to create a socketpair (which is
nontrivial) and two watchers: an I/O watcher and a timeout watcher.

I<request>, the most important value, is the time it takes to handle a
single "request", that is, reading the token from the pipe and forwarding
it to another server. This includes deleting the old timeout and creating
a new one that moves the timeout into the future.

=head3 Results

    name sockets create  request 
      EV   20000  69.01    11.16 
    Perl   20000  73.32    35.87 
   Event   20000 212.62   257.32 
    Glib   20000 651.16  1896.30 
     POE   20000 349.67 12317.24 uses POE::Loop::Event

=head3 Discussion

This benchmark I<does> measure scalability and overall performance of the
particular event loop.

EV is again fastest. Since it is using epoll on my system, the setup time
is relatively high, though.

Perl surprisingly comes second. It is much faster than the C-based event
loops Event and Glib.

Event suffers from high setup time as well (look at its code and you will
understand why). Callback invocation also has a high overhead compared to
the C<< $_->() for .. >>-style loop that the Perl event loop uses. Event
uses select or poll in basically all documented configurations.

Glib is hit hard by its quadratic behaviour w.r.t. many watchers. It
clearly fails to perform with many filehandles or in busy servers.

POE is still completely out of the picture, taking over 1000 times as long
as EV, and over 100 times as long as the Perl implementation, even though
it uses a C-based event loop in this case.

=head3 Summary

=over 4

=item * The pure perl implementation performs extremely well, considering
that it uses select.

=item * Avoid Glib or POE in large projects where performance matters.

=back

=head2 BENCHMARKING SMALL SERVERS

While event loops should scale (and select-based ones do not...) even to
large servers, most programs we (or I :) actually write have only a few
I/O watchers.

In this benchmark, I use the same benchmark program as in the large server
case, but it uses only eight "servers", of which three are active at any
one time. This should reflect performance for a small server relatively
well.

The columns are identical to the previous table.

=head3 Results

    name sockets create request 
      EV      16  20.00    6.54 
    Perl      16  25.75   12.62 
   Event      16  81.27   35.86 
    Glib      16  32.63   15.48 
     POE      16 261.87  276.28 uses POE::Loop::Event

=head3 Discussion

The benchmark tries to test the performance of a typical small
server. While knowing how various event loops perform is interesting, keep
in mind that their overhead in this case is usually not as important, due
to the small absolute number of watchers (that is, you need efficiency and
speed most when you have lots of watchers, not when you only have a few of
them).

EV is again fastest.

Perl again comes second. It is noticably faster than the C-based event
loops Event and Glib, although the difference is too small to really
matter.

POE also performs much better in this case, but is is still far behind the
others.

=head3 Summary

=over 4

=item * C-based event loops perform very well with small number of
watchers, as the management overhead dominates.

=back


=head1 FORK

Most event libraries are not fork-safe. The ones who are usually are
because they are so inefficient. Only L<EV> is fully fork-aware.

If you have to fork, you must either do so I<before> creating your first
watcher OR you must not use AnyEvent at all in the child.


=head1 SECURITY CONSIDERATIONS

AnyEvent can be forced to load any event model via
$ENV{PERL_ANYEVENT_MODEL}. While this cannot (to my knowledge) be used to
execute arbitrary code or directly gain access, it can easily be used to
make the program hang or malfunction in subtle ways, as AnyEvent watchers
will not be active when the program uses a different event model than
specified in the variable.

You can make AnyEvent completely ignore this variable by deleting it
before the first watcher gets created, e.g. with a C<BEGIN> block:

  BEGIN { delete $ENV{PERL_ANYEVENT_MODEL} }

  use AnyEvent;


=head1 SEE ALSO

Event modules: L<Coro::EV>, L<EV>, L<EV::Glib>, L<Glib::EV>,
L<Coro::Event>, L<Event>, L<Glib::Event>, L<Glib>, L<Coro>, L<Tk>,
L<Event::Lib>, L<Qt>, L<POE>.

Implementations: L<AnyEvent::Impl::CoroEV>, L<AnyEvent::Impl::EV>,
L<AnyEvent::Impl::CoroEvent>, L<AnyEvent::Impl::Event>, L<AnyEvent::Impl::Glib>,
L<AnyEvent::Impl::Tk>, L<AnyEvent::Impl::Perl>, L<AnyEvent::Impl::EventLib>,
L<AnyEvent::Impl::Qt>, L<AnyEvent::Impl::POE>.

Nontrivial usage examples: L<Net::FCP>, L<Net::XMPP2>.


=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

