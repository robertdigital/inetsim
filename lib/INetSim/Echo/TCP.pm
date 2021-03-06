# -*- perl -*-
#
# INetSim::Echo::TCP - A fake TCP echo server
#
# RFC 862 - Echo Protocol
#
# (c)2007-2010 Matthias Eckert, Thomas Hungenberg
#
# Version 0.50  (2010-04-12)
#
# For history/changelog see bottom of this file.
#
#############################################################

package INetSim::Echo::TCP;

use strict;
use warnings;
use base qw(INetSim::Echo);



sub configure_hook {
    my $self = shift;

    $self->{server}->{host}   = &INetSim::Config::getConfigParameter("Default_BindAddress"); # bind to address
    $self->{server}->{port}   = &INetSim::Config::getConfigParameter("Echo_TCP_BindPort");  # bind to port
    $self->{server}->{proto}  = 'tcp';                                      # TCP protocol
    $self->{server}->{user}   = &INetSim::Config::getConfigParameter("Default_RunAsUser");       # user to run as
    $self->{server}->{group}  = &INetSim::Config::getConfigParameter("Default_RunAsGroup");    # group to run as
    $self->{server}->{setsid} = 0;                                       # do not daemonize
    $self->{server}->{no_client_stdout} = 1;                             # do not attach client to STDOUT
    $self->{server}->{log_level} = 0;                                    # do not log anything

    $self->{servicename} = &INetSim::Config::getConfigParameter("Echo_TCP_ServiceName");
    $self->{max_childs} = &INetSim::Config::getConfigParameter("Default_MaxChilds");
    $self->{timeout} = &INetSim::Config::getConfigParameter("Default_TimeOut");
}



sub pre_loop_hook {
    my $self = shift;

    $0 = "inetsim_$self->{servicename}";
    &INetSim::Log::MainLog("started (PID $$)", $self->{servicename});
}



sub pre_server_close_hook {
    my $self = shift;

    &INetSim::Log::MainLog("stopped (PID $$)", $self->{servicename});
}



sub fatal_hook {
    my $self = shift;

    &INetSim::Log::MainLog("failed!", $self->{servicename});
    exit 0;
}



sub process_request {
    my $self = shift;
    my $client = $self->{server}->{client};
    my $rhost = $self->{server}->{peeraddr};
    my $rport = $self->{server}->{peerport};
    my $stat_success = 0;

    &INetSim::Log::SubLog("[$rhost:$rport] connect", $self->{servicename}, $$);
    if ($self->{server}->{numchilds} >= $self->{max_childs}) {
        print $client "Maximum number of connections ($self->{max_childs}) exceeded.\n";
        &INetSim::Log::SubLog("[$rhost:$rport] Connection refused - maximum number of connections ($self->{max_childs}) exceeded.", $self->{servicename}, $$);
    }
    else {
        eval {
            local $SIG{'ALRM'} = sub { die "TIMEOUT" };
            alarm($self->{timeout});
            while (my $line = <$client>) {
                print $client $line;
                $line =~ s/^[\r\n]+//g;
                $line =~ s/[\r\n]+$//g;
                if ($line ne "") {
                    &INetSim::Log::SubLog("[$rhost:$rport] recv: $line", $self->{servicename}, $$);
                    &INetSim::Log::SubLog("[$rhost:$rport] send: $line", $self->{servicename}, $$);
                    $stat_success = 1;
                }
                alarm($self->{timeout});
            }
            alarm(0);
        };
    }
    if ($@ =~ /TIMEOUT/) {
        &INetSim::Log::SubLog("[$rhost:$rport] disconnect (timeout)", $self->{servicename}, $$);
    }
    else {
        &INetSim::Log::SubLog("[$rhost:$rport] disconnect", $self->{servicename}, $$);
    }
    &INetSim::Log::SubLog("[$rhost:$rport] stat: $stat_success", $self->{servicename}, $$);
}



1;
#############################################################
#
# History:
#
# Version 0.50   (2010-04-12) me
# - undo changes from version 0.45 because it's already implemented
#   in the log module
#
# Version 0.49   (2009-10-28) me
# - improved some code parts
#
# Version 0.48   (2008-08-27) me
# - added logging of process id
#
# Version 0.47   (2008-03-19) me
# - added timeout after inactivity of n seconds, using new
#   config parameter Default_TimeOut
#
# Version 0.46  (2007-12-31) th
# - change process name
#
# Version 0.45  (2007-05-08) th
# - replace non-printable characters with "." before logging
#
# Version 0.44  (2007-04-26) th
# - use getConfigParameter
#
# Version 0.43  (2007-04-21) me
# - added logging of status for use with &INetSim::Report::GenReport()
#
# Version 0.42  (2007-04-05) th
# - changed check for MaxChilds, BindAddress, RunAsUser and
#   RunAsGroup
#
# Version 0.41  (2007-03-26) th
# - added logging of refused connections
#
# Version 0.4   (2007-03-23) th
# - split TCP and UDP servers to separate modules
# - rewrote module to use INetSim::GenericServer
#
# Version 0.3   (2007-03-20) th
# - changed echo_tcp for use with generic tcp_server
#
# Version 0.2   (2007-03-19) th
# - rewrote echo_tcp to serve multiple connections
# - added logging of remote port
#
# Version 0.1   (2007-03-18) me
#
#############################################################
