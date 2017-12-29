SHELL := /bin/bash

all: run

pipeline.vvp: ../pipeline.v ../clog2.v ../mem.v pipeline_tb.v
	@echo "Building..."
	iverilog -Wall -Wno-timescale -o pipeline.vvp ../pipeline.v ../clog2.v ../mem.v pipeline_tb.v
	@echo "Done building."
 
run: pipeline.vvp
	@echo "Simulating..."
	@./pipeline.vvp
	@echo "Done simulating."

clean:
	rm -f pipeline.vvp

