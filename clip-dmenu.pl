#!/usr/bin/env perl
use strict;
use warnings;

use Getopt::Long;
use List::Util qw(first);
use IPC::Open2;

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
    -f         specifies path to config file
    --background
    -b         run selected command in the background
    --command
    -c         specify command to run instead of `dmenu`
    --help
    -h         show this help
    --version  show version information
END
	exit;
}

sub has_clipboard_module {
	return eval {
		require Clipboard;
		import Clipboard;
		1;
	};
}

sub get_clipboard_module {
	return Clipboard->paste
}

sub get_clipboard_external {
	return `xclip -o -sel clip`;
}

sub get_clipboard {
	if (has_clipboard_module()) {
		return get_clipboard_module();
	} else {
		return get_clipboard_external();
	}
}

sub read_lines {
	my $file_name = shift;
	my $fun = shift;
	open my $fh, '<', $file_name or return;
	while (my $line = <$fh>) {
		chomp $line;
		$fun->($line);
	}
	return 1;
}

sub check_ignored {
	my $line = shift;
	return ($line =~ m/^\s*#/ or $line =~ m/^\s*$/);
}

sub read_config {
	my $config_file_name = shift;
	my @labels = ();
	my @commands = ();
	read_lines($config_file_name, sub {
		my $line = shift;
		if (check_ignored($line)) {
			return;
		}
		my ($name, $cmd) = split('\t', $line, 2);
		if (defined $name and defined $cmd) {
			push @labels, $name;
			push @commands, $cmd;
		} else {
			print STDERR "Ignoring malformed entry '$line'\n";
		}
	}) or die "cannot read config file $config_file_name";
	return (\@labels, \@commands)
}

sub run_dmenu {
	my $cmd = shift;
	my $labels = shift;
	my $all_names = join "\n", @$labels;
	open2(*Reader, *Writer, $cmd);
	print Writer $all_names;
	close Writer;
	my $selected_name = <Reader>;
	close Reader;
	return $selected_name;
}

my $config_file_name = $o{'file'} || ($ENV{XDG_CONFIG_HOME} || "$ENV{HOME}/.config") . '/clip-dmenu/config';
my ($labels, $commands) = read_config($config_file_name);
my $selected_name = run_dmenu($o{'cmd'}, $labels);
if ((not defined $selected_name) or ($selected_name eq '')) {
	exit;
}
chomp $selected_name;
my $idx = first { @{$labels}[$_] eq $selected_name } 0 .. $#{$labels};
my $selected_cmd = @{$commands}[$idx];
my $clipboard = get_clipboard();
$selected_cmd =~ s/%s/$clipboard/g;
if ($o{'background'}) {
        $selected_cmd .= ' &';
}
system($selected_cmd);
