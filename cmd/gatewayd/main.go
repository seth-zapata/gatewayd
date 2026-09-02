// Command gatewayd is an LLM gateway and model router.
//
// See SPEC.md. This file is scaffolding only: it compiles and prints a version,
// and nothing else. The HTTP server, handler, and Provider wiring are Stage 1,
// which is a red stage — Seth writes it.
package main

import (
	"fmt"
	"os"
	"runtime/debug"
)

// version is overridden at build time via -ldflags. See the Makefile.
var version = "dev"

func main() {
	if len(os.Args) > 1 && os.Args[1] == "version" {
		fmt.Println(buildInfo())
		return
	}
	fmt.Fprintf(os.Stderr, "gatewayd %s: no server yet — see SPEC.md §3 Stage 1\n", buildInfo())
	os.Exit(1)
}

func buildInfo() string {
	rev := "unknown"
	if bi, ok := debug.ReadBuildInfo(); ok {
		for _, s := range bi.Settings {
			if s.Key == "vcs.revision" && len(s.Value) >= 7 {
				rev = s.Value[:7]
			}
		}
	}
	return fmt.Sprintf("%s (%s)", version, rev)
}
