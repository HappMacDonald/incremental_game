#!/bin/perl

use strict;
use warnings;
use Math::Round qw(nearest);

my $esc = "\x{1B}[";
my $score = 0;
my $totalScore = 0;
my $defaultIncrement = 1.15;

my @suffixes = ('', qw(K M B T Qa Qt Sx Sp Oc Nn Dc UDc DDc TDc QaDC QtDC ));
my $buildings = [
	{ name => 'A', baseCost => 1e1, amplify => 1e-1 },
	{ name => 'B', baseCost => 1e3, amplify => 1e0 },
	{ name => 'C', baseCost => 1e6, amplify => 1e2 },
	{ name => 'D', baseCost => 1e10, amplify => 1e5 },
	{ name => 'E', baseCost => 1e15, amplify => 1e9 },
];

for my $bldg (@$buildings)
{
	HashAlternate($bldg, 'costIncrement', $defaultIncrement);
	HashAlternate($bldg, 'owned', 0);
}

sub ClearScreen { print $esc ."2J"; }

sub HashAlternate
{
  $_[0]->{$_[1]} = $_[2] unless(defined $_[0]->{$_[1]});
}

sub CalculateCost
{
	my $bldg = shift;
	$bldg->{baseCost} * $bldg->{costIncrement} ** $bldg->{owned};
}

sub CalculateClickPower
{
	my $ret = 1;
	for my $bldg (@$buildings)
	{
		$ret += $bldg->{amplify} * $bldg->{owned};
	}
	$ret;
}

sub PrintNumber
{
	my $num = shift;
	for my $idx (@suffixes)
	{
		if($num>=1e3) { $num /= 1e3; next; }
		return(nearest(1e-3, $num) . $idx);
	}
	"inf";
}

sub PlayRound
{
  ClearScreen();
	
	for my $bldg (@$buildings)
	{
		my $cost = CalculateCost($bldg);
		print $esc . ($score < $cost?"31m":"32;1m");
		print "$bldg->{name} costs ". PrintNumber($cost) .".\tYou own ". PrintNumber($bldg->{owned}) ." of them currently.\n";
		print $esc ."0m";
	}
	
	my $clickPower = CalculateClickPower();
	print "Score: \t". PrintNumber($score) ."\n";
	print "Click Power: \t". PrintNumber($clickPower) ."\n";
	my $cmd;
	$cmd = <STDIN>;
	$score += $clickPower;

	for my $bldg (@$buildings)
	{
		next unless($cmd =~ /\b((\d+)\s*)?$bldg->{name}\b/i);
		my $qty = $1;
		$qty = 1 unless(defined $qty && $qty>0);
		$qty = 1e3 unless($qty<=1e3);
		while(CalculateCost($bldg) < $score && $qty-->0)
		{
			$score -= CalculateCost($bldg);
			$bldg->{owned}++;
		}
	}
}

while(1)
{
	PlayRound();
}

# Black: 30m
# Red: 31m
# Green: 32m
# Yellow: 33m
# Blue: 34m
# Magenta: 35m
# Cyan: 36m
# White: 37m

# Reset: 0m
# Bright color XX;1m