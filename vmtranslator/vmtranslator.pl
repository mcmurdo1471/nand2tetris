#!/bin/perl
##

use strict;
use warnings;
use File::BaseName;
use VmTranslator::Parser;
use VmTranslator::CodeWriter;

use feature qw/say/;

my $path = shift;
my $asm = shift;

my $DEBUG_OUTPUT = 1;
my $REAL_OUTPUT = 1;
my $filecounter = 0;

# One CodeWriter per asm
my $codewriter = VmTranslator::CodeWriter->new( filename => $asm );

# Write the VM initialisation
$codewriter->writeInit;


if(-d $path) {
	say 'Directory';
	
	opendir my $dir, $path or die "Cannot open directory: $!";
	my @files = readdir $dir;
	closedir $dir;
	
	foreach my $file (@files) {
		if($file =~ /\.vm$/) {
			doFile($file);
		}
	}
}
else {
	doFile($path);
}

sub basename {
	# Until I get File::Basename installed
	my $path = shift;
	my $filename = "file$filecounter" . ".vm";
	$filecounter++;
	return $filename;
}

sub doFile {

	my $path = shift;
	
	my $vmname = basename($path);
	$vmname =~ tr/\.vm$//;

	my $parser = VmTranslator::Parser->new( filename => $path );
	
	if($DEBUG_OUTPUT) {
		say $path;
		say $vmname;
	}
	
	while($parser->hasMoreCommands) {
		$parser->advance;
		
		my $commandType = $parser->commandType();
		
		if($DEBUG_OUTPUT) {
			my $arg1 = ($commandType ne "C_RETURN") ? $parser->arg1() :"no";
			my $arg2 = ($commandType =~ /C_PUSH|C_POP|C_FUNCTION|C_CALL/) ? $parser->arg2() : "no";
			
			if(!$arg1) {$arg1 = "stillno"};
			
			my $out = "CommandType: $commandType\t";
			
			$out .= "Arg1: $arg1\t";
			$out .= "Arg2: $arg2";
			
			say $out;
		}

		if($REAL_OUTPUT) {
			$codewriter->setFileName($vmname);
			if($commandType =~ /C_PUSH|C_POP/) {
				$codewriter->writePushPop($commandType, $parser->arg1, $parser->arg2);
			}
			if($commandType =~ /C_ARITHMETIC/) {
				$codewriter->writeArithmetic($parser->arg1);
			}
			if($commandType eq "C_LABEL") {
				$codewriter->writeLabel($parser->arg1);
			}
			if($commandType eq "C_GOTO") {
				$codewriter->writeGoto($parser->arg1);
			}
			if($commandType eq "C_IF") {
				$codewriter->writeIf($parser->arg1);
			}
		}
	}

}