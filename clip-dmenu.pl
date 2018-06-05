#!/usr/bin/env perl
use strict;
use warnings;

# TODO: use xdg to get .config dir #
my $config_file_name = $ENV{'HOME'} . '/.config/clip-dmenu/config';
open my $fh, '<', $config_file_name or die "cannot open config file $config_file_name";

my %commands;
while (my $line = <$fh>) {
	my ($name, $cmd) = split('\t', $line, 3);
	$commands{$name} = $cmd;
}
my $all_names = join "\n", keys %commands;
# TODO: make sure this command is safe #
# TODO: support dmenu, rofi and others #
my $selected_name = `echo "$all_names" | rofi -dmenu`;
if ($selected_name eq '') {
	exit;
}
chomp $selected_name;
my $selected_cmd = $commands{$selected_name};
chomp $selected_cmd;
# TODO: use some perl module to get clipboard #
my $clipboard = `xclip -sel clip -o`;
$selected_cmd =~ s/%s/$clipboard/g;
# TODO: add flag to run process in background #
$selected_cmd .= ' &';
system($selected_cmd);
