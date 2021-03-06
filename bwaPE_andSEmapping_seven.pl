#!/usr/bin/env perl

use strict;
use warnings;
use File::Spec;



my $PI = `echo $$` ;    chomp($PI) ;

#debug 
my $debug = 0 ; 

if (@ARGV != 2) {
    print STDERR "usage: $0 input threads\n" ; 
    print STDERR "This is for Tsai's another whatever data \n" ; 

    exit(1);
}

#my $ref = "/mnt/nas1/ijt/db/hg19/GRCh38_full_analysis_set_plus_decoy_hla.fa" ; 
#my $ref = "/home/ishengtsai/db/hg19/ucsc.hg19.fasta" ;
my $ref = "/mnt/nas1/ijt/db/hg19/ucsc.hg19.fasta" ; 

#my $picardbin = "/usr/local/bioinfo/picard-tools-1.130/picard.jar" ; 
my $picardbin = "/home/ijt/bin/picard.jar" ; 

#my $gatkjar = "/usr/local/bioinfo/GenomeAnalysisTK.jar" ; 
my $gatkjar = "/home/ijt/bin/GenomeAnalysisTK.jar" ; 

my $dict = "/mnt/nas1/ijt/db/hg19/ucsc.hg19.dict" ; 

#my $exomeBed = "/mnt/nas1/ijt/T1D/Agilent_SureSelect_Exome_V6.bed" ; 
my $exomeBed = "/mnt/nas1/ijt/seven/Seqcap3.0/SeqCapEZ_Exome_v3.0_Design_Annotation_files/SeqCap_EZ_Exome_v3_hg19_capture_targets.bed" ; 


my $input = shift ; 
my $output = $input ; 
my $cpu = shift ; 

#java set
system("java -Xmx6g -version ;  ") ; 

# make tmp dir
system("mkdir tmp") ; 


#bwa
my $bwacommand = "/home/ijt/bin/bwa/bwa mem -t $cpu -M -R '\@RG\\tID:$output\\tLB:T1D\\tSM:$output\\tPL:ILLUMINA' $ref $input\_R1.fastq.gz $input\_R2.fastq.gz > $output.PE.sam" ;
#system_call("$bwacommand") ; 

$bwacommand = "/home/ijt/bin/bwa/bwa mem -t $cpu -M -R '\@RG\\tID:$output\\tLB:T1D\\tSM:$output\\tPL:ILLUMINA' $ref $input\_1_up.fq.gz > $output.SE.sam" ;
#system_call("$bwacommand") ;

my $samtools = "samtools view --threads $cpu -o $output.PE.bam  $output.PE.sam  ;  samtools sort --threads $cpu -o $output.PE.sorted.bam  $output.PE.bam " ;
#system_call("$samtools") ;

$samtools = "samtools view --threads $cpu -o $output.SE.bam  $output.SE.sam  ;  samtools sort --threads $cpu -o $output.SE.sorted.bam  $output.SE.bam " ;
#system_call("$samtools") ;


# Merge
my $merge = "samtools merge --threads $cpu $output.sorted.bam $output.PE.sorted.bam $output.SE.sorted.bam" ;
#system_call("$merge") ; 


#mark duplicates
#system_call("java -Xmx6g -jar /home/ijt/bin/picard.jar MarkDuplicates METRICS_FILE=metrics CREATE_INDEX=true INPUT=$output.sorted.bam OUTPUT=$output.markdup.bam") ; 

#stats
#system_call("bamtools stats -in $output.markdup.bam -insert > $output.markdup.bam.stats") ;


#indel calling ; First declare the region
#system_call("java -Xmx6g -Djava.io.tmpdir=`pwd`/tmp -jar $gatkjar -T RealignerTargetCreator -R $ref -I $output.markdup.bam -known /mnt/nas1/ijt/db/hg19/1000G_phase1.indels.hg19.sites.vcf -known /mnt/nas1/ijt/db/hg19/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf -o $output.markdup.bam.realignment.target.list -L $exomeBed -nct 1 -nt $cpu ") ; 

# local realignment
#system_call("java -Xmx6g -Djava.io.tmpdir=`pwd`/tmp -jar $gatkjar -T IndelRealigner -targetIntervals $output.markdup.bam.realignment.target.list -R $ref -I $output.markdup.bam -o $output.markdup.realigned.bam -known /mnt/nas1/ijt/db/hg19/1000G_phase1.indels.hg19.sites.vcf -known /mnt/nas1/ijt/db/hg19/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf        ") ; 

# base recalibration
#system_call("java -Xmx6g -Djava.io.tmpdir=`pwd`/tmp -jar $gatkjar -T BaseRecalibrator -I $output.markdup.realigned.bam -R $ref -knownSites /mnt/nas1/ijt/db/hg19/dbsnp_138.hg19.vcf -knownSites /mnt/nas1/ijt/db/hg19/1000G_phase1.indels.hg19.sites.vcf -knownSites /mnt/nas1/ijt/db/hg19/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf  -o $output.markdup.recal_data.table -L $exomeBed -nct $cpu -nt 1 ") ; 

# print recalibrated bam
#system_call("java -Xmx6g -Djava.io.tmpdir=`pwd`/tmp -jar $gatkjar -T PrintReads -I $output.markdup.realigned.bam -R $ref -BQSR $output.markdup.recal_data.table -o $output.markdup.realigned.recalibrated.bam -L $exomeBed -nct $cpu -nt 1 ") ; 

# call SNPs!
# https://software.broadinstitute.org/gatk/documentation/article?id=3893

#1. Variant calling
#Run the HaplotypeCaller on each sample's BAM file(s) (if a sample's data is spread over more than one BAM, then pass them all in together) to create single-sample gVCFs, with the option -emitRefConfidence GVCF, and using the .g.vcf extension for the output file
#Note that versions older than 3.4 require passing the options --variant_index_type LINEAR --variant_index_parameter 128000 to set the correct index strategy for the output gVCF.

#my $HaplotypeCallerCommand = "java -Xmx6g -Djava.io.tmpdir=`pwd`/tmp -jar $gatkjar -T HaplotypeCaller -R $ref -I $output.markdup.realigned.recalibrated.bam -L $exomeBed " .
#    " --dbsnp /mnt/nas1/ijt/db/hg19/1000G_phase1.indels.hg19.sites.vcf --emitRefConfidence GVCF -o $output.raw.snps.indels.g.vcf " ; 
#system_call("$HaplotypeCallerCommand") ; 

# https://software.broadinstitute.org/gatk/documentation/article?id=2803

my $HaplotypeCallerCommand = "java -Xmx6g -Djava.io.tmpdir=`pwd`/tmp -jar $gatkjar -T HaplotypeCaller -R $ref -I $output.markdup.realigned.recalibrated.bam --genotyping_mode DISCOVERY -stand_call_conf 30 " .
    " --dbsnp /mnt/nas1/ijt/db/hg19/1000G_phase1.indels.hg19.sites.vcf --emitRefConfidence GVCF -o $output.raw.snps.indels.g.vcf   " ;
system_call("$HaplotypeCallerCommand") ;



# delete transient files
#system_call("rm $output.sam") ; 

print "All done! Pipeline all executed\n" ; 


# usage: system_call(string)
# Runs the string as a system call, dies if call returns nonzero error code
sub system_call {
    my $cmd  = shift;
    print "Command:\n$cmd\n\n";
    system($cmd) ; 

}
