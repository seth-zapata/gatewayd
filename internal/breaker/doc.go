// Package breaker implements a per-provider circuit breaker.
//
// SPEC.md §3 Stage 5 (red): closed -> open -> half-open. The design question
// that stage exists to answer is mutex vs channel for the state machine.
package breaker
