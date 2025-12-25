# 🏰 Kube-Sandcastle

High-Performance, Secure, and Kueue-Native Runtime for AI Agents
Kube-Sandcastle is an infrastructure layer designed to solve the "Agent Execution Gap."
It allows you to run untrusted, AI-generated code with the security of a Virtual Machine
and the speed of a Goroutine, all while staying native to the Kubernetes resource model via Kueue.

## 🚀 The Problem: "The Agent Execution Gap"

AI Agents (AutoGPT, OpenDevin, LangChain) generate Python code that needs to be executed immediately.
Current Kubernetes patterns fail here:

Security Risk: Running os.system("rm -rf /") in a standard container or a shared Ray worker
is a disaster waiting to happen.

High Latency: Creating a new Kubernetes Job takes 2–5 seconds. Agents require sub-100ms
response times to feel "intelligent."

Resource Waste: Standard Pods are "heavy." Keeping thousands of them idle just for occasional
agent tasks burns money.

## 🏗️ The Architecture: "Sandbox-as-a-Goroutine"

Kube-Sandcastle treats compute resources like a bank:

Wholesale (Kueue): We reserve large chunks of CPU/GPU via Kueue Workloads to create "Warm Pools."

Retail (Sandbox Proxy): A high-speed gRPC Gateway "slices" these resources into thousands of micro-sandboxes.

Hard Isolation: Each task runs in a gVisor (runsc) sandbox under a unique, non-root Linux
user with strict seccomp profiles.

## ✨ Key Features

- Sub-100ms Latency: Bypasses the K8s Control Plane for task execution.
- Kernel-Level Isolation: Powered by gVisor to prevent container escapes.
- Instant State Reset: Every execution starts with a clean filesystem and memory state.
- Kueue-Native Accounting: Real-time reporting of CPU/RAM usage (syscall.Getrusage) back to Kueue for precise quota management.