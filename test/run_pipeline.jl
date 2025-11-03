using Test
using OkErrorHandling

@testset "@run_pipeline tests" begin

    @testset "Interactive mode: errors propagate normally" begin
        # In interactive mode (REPL), errors should throw normally
        @test_throws ErrorException @run_pipeline error("test error")
        @test_throws ArgumentError @run_pipeline throw(ArgumentError("bad arg"))
    end

    @testset "Interactive mode: successful execution" begin
        # Should execute and return normally
        result = @run_pipeline begin
            x = 1 + 1
            x * 2
        end
        @test result == 4
    end

    @testset "Non-interactive mode simulation" begin
        # Test behavior when isinteractive() returns false
        # We need to spawn a separate Julia process to truly test CLI mode

        # Test successful execution
        script = """
        using OkErrorHandling
        @run_pipeline begin
            println("Success")
        end
        """
        result = read(pipeline(`julia --startup-file=no -e $(script)`), String)
        @test occursin("Success", result)

        # Test error handling with exit code
        error_script = """
        using OkErrorHandling
        @run_pipeline error("Pipeline failed")
        """
        proc = run(pipeline(`julia --startup-file=no -e $(error_script)`), wait=false)
        wait(proc)
        @test proc.exitcode == 1

        # Test ArgumentError exit code
        arg_error_script = """
        using OkErrorHandling
        @run_pipeline throw(ArgumentError("bad argument"))
        """
        proc = run(pipeline(`julia --startup-file=no -e $(arg_error_script)`), wait=false)
        wait(proc)
        @test proc.exitcode == 2

        # Test InterruptException exit code
        interrupt_script = """
        using OkErrorHandling
        @run_pipeline throw(InterruptException())
        """
        proc = run(pipeline(`julia --startup-file=no -e $(interrupt_script)`), wait=false)
        wait(proc)
        @test proc.exitcode == 130
    end

end
