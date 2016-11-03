#Create a simulator object
set ns [new Simulator]

#Define different colors for data flows (for NAM)
$ns color 1 Blue
$ns color 2 Red
$ns color 3 Green
$ns color 4 Yellow
$ns color 5 Brown

#Open the NAM trace file
set nf [open out.nam w]
$ns namtrace-all $nf
set num 6
# Open the tr file
set tf [open all_out.tr w]
$ns trace-all $tf
array set tr {}
for {set i 1} {$i < $num} {incr i} {
	set tr($i) [open ($i)_out.tr w]
}

#Define a 'finish' procedure
proc finish {} {
        global ns nf tf num tr

        $ns flush-trace
        #Close the NAM trace file
        close $nf 
        close $tf

        for {set i 1} {$i <=$num-1} {incr i} {
        	close $tr($i)
        }
        #Execute NAM on the trace file and show xgraph
        exec nam out.nam &
        exec xgraph (1)_out.tr (2)_out.tr (3)_out.tr (4)_out.tr (5)_out.tr -geometry 800x400 &
        exit 0
}

proc record {} {
		global num node tr tcpSink
		set ns [Simulator instance]
		set time 0.5
		set now [$ns now]
		for {set i 1} {$i < $num} {incr i} {
			set bw($i) [$tcpSink($i) set bytes_]
			puts $tr($i) "$now [expr $bw($i)/$time*8/1000000]"
			#Reset the bytes_ values on the traffic sinks
			$tcpSink($i) set bytes_ 0
		}
		#Re-schedule the procedure
        $ns at [expr $now+$time] "record"
}

for {set i 1} {$i <=$num} {incr i} {
	set node($i) [$ns node]
	if {$i<$num} {
		set tcp($i) [$ns node]
	}

	if {$i>1} {
		set past [expr {$i - 1}]
		$ns duplex-link $node($past) $node($i) 0.5Mb 100ms RED
		$ns duplex-link-op $node($past) $node($i) orient right
	}
	if {$i<$num} {
		$ns duplex-link $tcp($i) $node($i) 5Mb 20ms RED
		$ns duplex-link-op $tcp($i) $node($i) orient down
	}
		
}

for {set i 1} {$i <=$num-1} {incr i} {
	set tcpS($i) [new Agent/TCP]
	$tcpS($i) set class_ 2
	$ns attach-agent $tcp($i) $tcpS($i)
	$tcpS($i) set fid_ $i

	set tcpSink($i) [new Agent/TCPSink/DelAck]
	$ns attach-agent $node($num) $tcpSink($i)
	$ns connect $tcpS($i) $tcpSink($i)
	
	set ftpS($i) [new Application/FTP]
	$ftpS($i) attach-agent $tcpS($i)
	$ftpS($i) set type_ FTP
}

# start the simulation
$ns at 0.0 "record"
set start 0.0
set end 12.0
set startSend 0.1
set stopSend 10.0
for {set i 1} {$i <=5} {incr i} {
	$ns at $startSend "$ftpS($i) start"
	$ns at $stopSend "$ftpS($i) stop"
}

$ns at $end "finish"
#Run the simulation
$ns run