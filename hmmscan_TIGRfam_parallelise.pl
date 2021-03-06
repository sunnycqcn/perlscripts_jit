#!/usr/bin/perl -w
use strict;



my $PI = `echo $$` ; chomp($PI);



if (@ARGV != 2) {
    print "$0 fasta prefix\n" ; 

	exit ;
}

my $fasta = shift ;
my $prefix = shift ;

my $ram = 3 ;
my $parameters = '--acc --notextw --cut_nc --noali' ;
my $programs = 'hmmscan ' ;
my $db = ' /home/ishengtsai/db/TIGRFAM/TIGRFAMs_13.0_HMM.LIB ' ; 


my $location = "" ; 


my $random_no =  int(rand(10000));


my $in_dir = "$prefix.$fasta.$random_no" ;



mkdir "$in_dir" or die "oops" ;




print '--------------------------------------------------------------------------------------' ;
print "\njit's small blast \n" ;
print "script path: $location\n" ;
print "Random ID: $random_no \n" ;
print "\nfasta file = $fasta\n" ;
print "in_dir  = $in_dir\n" ;

print "\nfinal file = should be $prefix.final.result\n" ;
print '--------------------------------------------------------------------------------------' . "\n\n";





my %contig_seq = () ;
my $read_seq = '' ;
my $read_name = '' ;

open (IN, "$fasta") or die "oops!\n" ;


	while (<IN>) {
	    if (/^>(\S+)/) {
		$read_name = $1 ;
		$read_seq = "" ;
		
		while (<IN>) {

			if (/^>(\S+)/) {
			    
				$contig_seq{$read_name} = $read_seq ;

			    $read_name = $1 ;
			    $read_seq = "" ;



			}
			else {
			    chomp ;
			    $read_seq .= $_ ;
			}


		}

	    }
	}

close(IN) ;
$contig_seq{$read_name} = $read_seq ;


chdir "$in_dir" or die "can't change dir!\n" ;

my $count = 1 ;
my $realcount = 1 ; 

for my $seq_name (sort keys %contig_seq) {

    if ( $count == 51 ) {
	$count = 1 ; 
	$realcount++ ; 
    }

    if ( $count == 1 ) {
	close(OUT); 
	open OUT, ">", "$realcount.fa" or die "oooops\n" ;
    }

    print OUT ">$seq_name\n$contig_seq{$seq_name}\n" ;


    $count++ ;
}




# submit the job
my $qsub_command = '' ; 


# blast mapping
open QSH, '>', "map_array.sh" or die "2" ;
#print QSH "$command -db $db -outfmt 5 -evalue $evalue -query " . '$SGE_TASK_ID.fa -out ' . "../$out_dir/" . '$SGE_TASK_ID.out' ;
print QSH "$programs $parameters --tblout " . '$SGE_TASK_ID.tableout  --domtblout $SGE_TASK_ID.domainout ' . "$db" . ' $SGE_TASK_ID.fa >  $SGE_TASK_ID.out' ; 


$qsub_command = 'qsub -t 1-' . $realcount . ':1 -V -cwd -S /bin/bash -N waha' . $PI .  ' -l mem_req='. $ram . 'G,s_vmem=' . $ram . 'G map_array.sh';





print "\n\nsubmitting job!\n" ;
print "submitting jobs.. $qsub_command\n\n" ;

system("$qsub_command") ;




my $merge_command = "cat *.out > ../$fasta.$PI.hmmscan.$prefix.out \; cat *.tableout > ../$fasta.$PI.hmmscan.perseq.$prefix.out \; cat *.domainout > ../$fasta.$PI.hmmscan.perdomain.$prefix.out " ; 
$qsub_command = '/home/tk6/bin/python3/qsub.v2.py ' . ' --dep "waha' . $PI . '" 3 merge' . $PI . ' "' . "$merge_command" . '"';



print "send off bsub dependency! - merge everything!\n" ;
system("$qsub_command") ;




print "done! coffee break!\n" ;
