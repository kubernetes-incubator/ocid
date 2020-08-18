#!/usr/bin/env bats

load helpers

@test "crio commands" {
	run crio -c /dev/null config > /dev/null
	echo "$output"
	[ "$status" -eq 0 ]
	run crio badoption > /dev/null
	echo "$output"
	[ "$status" -ne 0 ]
}

@test "invalid ulimits" {
	run crio --default-ulimits doesntexist=2042
	echo $output
	[ "$status" -ne 0 ]
	[[ "$output" == *"invalid ulimit type: doesntexist"* ]]
	run crio --default-ulimits nproc=2042:42
	echo $output
	[ "$status" -ne 0 ]
	[[ "$output" == *"ulimit soft limit must be less than or equal to hard limit: 2042 > 42"* ]]
	# can't cover everything here, ulimits parsing is tested in
	# github.com/docker/go-units package
}

@test "invalid devices" {
	run crio --additional-devices /dev/sda:/dev/foo:123
	echo $output
	[ "$status" -ne 0 ]
	[[ "$output" == *"invalid device mode:"* ]]
	run crio --additional-devices /dev/sda:/dee/foo:rm
	echo $output
	[ "$status" -ne 0 ]
	[[ "$output" == *"invalid device mode:"* ]]
	run crio --additional-devices /dee/sda:rmw
	echo $output
	[ "$status" -ne 0 ]
	[[ "$output" == *"invalid device mode:"* ]]
}

@test "invalid metrics port" {
	mkdir -p "$TESTDIR/cni/net.d"
	opt="--cni-config-dir $TESTDIR/cni/net.d"
	run crio ${opt} --metrics-port foo --enable-metrics
	echo $output
	[ "$status" -ne 0 ]
	[[ "$output" == *'invalid value "foo" for flag'* ]]
	run crio ${opt} --metrics-port 18446744073709551616 --enable-metrics
	echo $output
	[ "$status" -ne 0 ]
	[[ "$output" == *"value out of range"* ]]
}

@test "invalid log max" {
	mkdir -p "$TESTDIR/cni/net.d"
	opt="--cni-config-dir $TESTDIR/cni/net.d"
	run crio ${opt} --log-size-max foo
	echo $output
	[ "$status" -ne 0 ]
	[[ "$output" == *'invalid value "foo" for flag'* ]]
}

@test "log max boundary testing" {
	mkdir -p "$TESTDIR/cni/net.d"
	opt="--cni-config-dir $TESTDIR/cni/net.d"
	# log size max is special zero value
	run crio ${opt} --log-size-max 0
	echo $output
	[ "$status" -ne 0 ]
	[[ "$output" == *"log size max should be negative or >= 8192"* ]]
	# log size max is less than 8192 and more than 0
	run crio ${opt} --log-size-max 8191
	echo $output
	[ "$status" -ne 0 ]
	[[ "$output" == *"log size max should be negative or >= 8192"* ]]
	# log size max is out of the range of 64-bit signed integers
	run crio ${opt} --log-size-max 18446744073709551616
	echo $output
	[ "$status" -ne 0 ]
	[[ "$output" == *"value out of range"* ]]
}
