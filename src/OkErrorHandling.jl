module OkErrorHandling

# Write your package code here.
export @run_pipeline

"""
    @run_pipeline ex

Executes expression `ex`.
- In non-interactive (CLI) mode: Wraps in a try/catch block.
  On error, logs a formatted message and calls `exit(1)`.
- In interactive (REPL) mode: Executes `ex` directly,
  allowing errors to throw normally for debugging.

# Example
```julia
using OkErrorHandling

function main()
    error("Hello!")
end

if !isempty(PROGRAM_FILE) && abspath(PROGRAM_FILE) == @__FILE__
    println("Running in CLI mode...")
    @run_pipeline main()
else
    # --- INTERACTIVE EXECUTION (REPL/VSCode) ---
    println("Running in REPL/interactive mode.")
    @run_pipeline main()
end
```

"""
macro run_pipeline(ex)
    quote
        if !isinteractive()
            # --- CLI Mode: Add the try...catch ---
            try
                $(esc(ex))
            catch e
                println(stderr, "\n" * "="^80)
                println(stderr, "❌ ERROR: Pipeline failed!")
                println(stderr, "="^80 * "\n")
                println(stderr, "Full Julia Stacktrace:\n")
                Base.showerror(stderr, e, catch_backtrace())
                println(stderr, "\n" * "="^80)
                exit(1)
            end
        else
            # --- Interactive Mode: Run raw ---
            # This lets errors throw normally in the REPL
            $(esc(ex))
        end
    end
end

end
