// Package provider defines the Provider interface and its implementations.
//
// SPEC.md §2: the interface stays at two methods. Implementations (Anthropic,
// Bedrock, OpenAI) each live in their own file in this package.
//
// Stage 1 (red): Anthropic, non-streaming.
// Stage 2 (red): streaming with correct cancellation.
// Stage 3 (red): Bedrock and OpenAI behind the same interface.
package provider
