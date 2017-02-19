#!/bin/perl
##

use strict;
use warnings;
use VmTranslator::Parser;

use feature qw/say/;

my $path = shift;

if(-d $path) {
	say 'Directory';
	# TODO Handle directory of files
}
else {
	# Assume file
	my $parser = VmTranslator::Parser->new( filename => $path );
	
	while($parser->hasMoreCommands) {
		$parser->advance;
		
		my $commandType = $parser->commandType();
		my $arg1 = ($parser->commandType() ne "C_RETURN") ? $parser->arg1() :"no";
		my $arg2 = ($parser->commandType() =~ /C_PUSH|C_POP|C_FUNCTION|C_CALL/) ? $parser->arg2() : "no";
		
		if(!$arg1) {$arg1 = "stillno"};
		
		my $out = "CommandType: $commandType\t";
		
		$out .= "Arg1: $arg1\t";
		$out .= "Arg2: $arg2";
		
		say $out;
	}
}