#!/usr/bin/env perl
use strict;
use warnings;

use FileHandle;
use IPC::Open2;
use Clipboard;
use File::XDG;

my $xdg = File::XDG->new(name => 'clip-dmenu');
# TODO: use xdg to get .config dir #
my $config_file_name = $xdg->config_home() . '/config';
open my $fh, '<', $config_file_name or die "cannot open config file $config_file_name";

my %commands;
while (my $line = <$fh>) {
	chomp $line;
	my ($name, $cmd) = split('\t', $line, 3);
	$commands{$name} = $cmd;
}
my $all_names = join "\n", keys %commands;
# TODO: support dmenu, rofi and others #
open2(*Reader, *Writer, 'rofi -dmenu');
print Writer $all_names;
close Writer;
my $selected_name = <Reader>;
close Reader;
chomp $selected_name;
if ($selected_name eq '') {
	exit;
}
my $selected_cmd = $commands{$selected_name};
my $clipboard = Clipboard->paste;
$selected_cmd =~ s/%s/$clipboard/g;
# TODO: add flag to run process in background #
$selected_cmd .= ' &';
system($selected_cmd);
