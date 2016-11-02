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

# Open the tr file
set tf [open out.tr w]
$ns trace-all $tf

#Define a 'finish' procedure
proc finish {} {
        global ns nf tf 
        $ns flush-trace
        #Close the NAM trace file
        close $nf 
        close $tf
        #Execute NAM on the trace file
        exec nam out.nam &
        exit 0
}

for {set i 1} {$i <=6} {incr i} {
	set node($i) [$ns node]
	if {$i<6} {
		set tcp($i) [$ns node]
	}

	if {$i>1} {
		set past [expr {$i - 1}]
		$ns duplex-link $node($past) $node($i) 0.5Mb 100ms DropTail
		$ns duplex-link-op $node($past) $node($i) orient right
	}
	if {$i<6} {
		$ns duplex-link $tcp($i) $node($i) 5Mb 20ms DropTail
		$ns duplex-link-op $tcp($i) $node($i) orient down
	}
		
}

for {set i 1} {$i <=5} {incr i} {
	set tcpS($i) [new Agent/TCP]
	$tcpS($i) set class_ 2
	$ns attach-agent $tcp($i) $tcpS($i)
	
	set tcpSink($i) [new Agent/TCPSink]
	$ns attach-agent $node(6) $tcpSink($i)
	$ns connect $tcpS($i) $tcpSink($i)
	$tcpS($i) set fid_ $i	

	set ftpS($i) [new Application/FTP]
	$ftpS($i) attach-agent $tcpS($i)
	$ftpS($i) set type_ FTP
}

# start the simulation
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