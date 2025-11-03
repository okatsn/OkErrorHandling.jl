module OkErrorHandling

# Write your package code here.
export @cli_entrypoint

"""
    @cli_entrypoint ex

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
    @cli_entrypoint main()
else
    # --- INTERACTIVE EXECUTION (REPL/VSCode) ---
    println("Running in REPL/interactive mode.")
    @cli_entrypoint main()
end
```

"""
macro cli_entrypoint(ex)
    quote
        if !isinteractive()
            # --- CLI Mode: Add the try...catch ---
            try
                # `esc(ex)` execute the expression ex using the variables and functions from the caller's scope (where the macro was invoked).
                $(esc(ex))
            catch e
                # The following functions won't be escaped. They will always refer to the functions available to your `OkErrorHandling` module. Even if the user does something strange like `exit = "my-string"`, your macro's catch block will still call the real `Base.exit(1)` and work correctly.
                println(stderr, "\n" * "="^80)
                println(stderr, "❌ ERROR: Pipeline failed!")
                println(stderr, "="^80 * "\n")
                println(stderr, "Full Julia Stacktrace:\n")
                Base.showerror(stderr, e, catch_backtrace())
                println(stderr, "\n" * "="^80)
                if e isa InterruptException
                    println(stderr, "Cancelled by user.")
                    exit(130)
                elseif e isa ArgumentError
                    println(stderr, "Usage error: $(e.msg)")
                    exit(2)
                else
                    # Customize formatting if you like
                    println(stderr, "❌ ERROR: Pipeline failed.\n")
                    Base.showerror(stderr, e, catch_backtrace())
                    println(stderr)
                    exit(1)
                end

            end
        else
            # --- Interactive Mode: Run raw ---
            # This lets errors throw normally in the REPL
            $(esc(ex))
        end
    end
end

end
