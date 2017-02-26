#!/bin/perl
##

use strict;
use warnings;
use VmTranslator::Parser;
use VmTranslator::CodeWriter;

use feature qw/say/;

my $path = shift;
my $asm = shift;

my $DEBUG_OUTPUT = 1;
my $REAL_OUTPUT = 1;

if(-d $path) {
	say 'Directory';
	# TODO Handle directory of files
}
else {
	# Assume file
	my $parser = VmTranslator::Parser->new( filename => $path );
	my $codewriter = VmTranslator::CodeWriter->new( filename => $asm );
	
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
			$codewriter->setFileName("foof.vm");
			if($commandType =~ /C_PUSH|C_POP/) {
				$codewriter->writePushPop($commandType, $parser->arg1, $parser->arg2);
			}
			if($commandType =~ /C_ARITHMETIC/) {
				$codewriter->writeArithmetic($parser->arg1);
			}
		}
		

	}
}