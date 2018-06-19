#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use List::Util qw(first);
use IPC::Open2;
use Clipboard;

use constant {
	VERSION => 0.10,
};

my %o = (
	help => 0,
	version => 0,
	file => undef,
	background => 0,
	cmd => 'dmenu',
);
GetOptions(
	'h|help' => \$o{'help'},
	'version' => \$o{'version'},
	'f|file=s' => \$o{'file'},
	'b|background' => \$o{'background'},
	'c|cmd=s' => \$o{'cmd'},
);

if ($o{'version'}) {
	my $s = <<END;
clip-dmenu v%s
END
	print sprintf($s, VERSION);
	exit;
}

if ($o{help}) {
	print <<END;
usage: clip-dmenu [OPTIONS]
  OPTIONS:
    --file
    -f       specifies path to config file
    --background
    -b       run selected command in the background
    --command
    -c       specify command to run instead of `dmenu`
    --help
    -h       show this help
END
	exit;
}

my $config_file_name = $o{'file'} || ($ENV{XDG_CONFIG_HOME} || "$ENV{HOME}/.config") . '/clip-dmenu/config';
open my $fh, '<', $config_file_name or die "cannot open config file $config_file_name";

my @labels = ();
my @commands = ();
while (my $line = <$fh>) {
	chomp $line;
	if ($line =~ m/^\s*#/ or $line =~ m/^\s*$/) {
		next;
	}
	my ($name, $cmd) = split('\t', $line, 3);
	if (defined $name and defined $cmd) {
		push @labels, $name;
		push @commands, $cmd;
	} else {
		print STDERR "Ignoring malformed entry '$line'\n";
	}
}
my $all_names = join "\n", @labels;
open2(*Reader, *Writer, $o{'cmd'});
print Writer $all_names;
close Writer;
my $selected_name = <Reader>;
close Reader;
if ((not defined $selected_name) or ($selected_name eq '')) {
	exit;
}
chomp $selected_name;
my $idx = first { $labels[$_] eq $selected_name } 0 .. $#labels;
my $selected_cmd = $commands[$idx];
my $clipboard = Clipboard->paste;
$selected_cmd =~ s/%s/$clipboard/g;
if ($o{'background'}) {
        $selected_cmd .= ' &';
}
system($selected_cmd);
