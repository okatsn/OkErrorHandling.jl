using Test
using OkErrorHandling

@testset "@cli_entrypoint tests" begin

    @testset "Successful execution" begin
        # Should execute and return normally
        result = @cli_entrypoint begin
            x = 1 + 1
            x * 2
        end
        @test result == 4
    end

    @testset "Interactive mode: errors propagate" begin
        # These tests verify that in interactive mode, errors throw normally
        # We spawn Julia in interactive mode to test this behavior

        interactive_error_script = """
        using OkErrorHandling
        using Test
        @test_throws ErrorException @cli_entrypoint error("test error")
        @test_throws ArgumentError @cli_entrypoint throw(ArgumentError("bad arg"))
        println("TESTS_PASSED")
        """
        result = read(pipeline(`julia --startup-file=no -i -e $(interactive_error_script)`), String)
        @test occursin("TESTS_PASSED", result)
    end

    @testset "Non-interactive mode: error handling" begin
        # Test behavior when isinteractive() returns false
        # We spawn separate Julia processes in non-interactive mode to test CLI behavior

        # Test successful execution in non-interactive mode
        script = """
        using OkErrorHandling
        @cli_entrypoint begin
            println("Success")
        end
        """
        result = read(pipeline(`julia --startup-file=no -e $(script)`), String)
        @test occursin("Success", result)

        # Test error handling with exit code
        error_script = """
        using OkErrorHandling
        @cli_entrypoint error("Pipeline failed")
        """
        proc = run(pipeline(`julia --startup-file=no -e $(error_script)`), wait=false)
        wait(proc)
        @test proc.exitcode == 1

        # Test ArgumentError exit code
        arg_error_script = """
        using OkErrorHandling
        @cli_entrypoint throw(ArgumentError("bad argument"))
        """
        proc = run(pipeline(`julia --startup-file=no -e $(arg_error_script)`), wait=false)
        wait(proc)
        @test proc.exitcode == 2

        # Test InterruptException exit code
        interrupt_script = """
        using OkErrorHandling
        @cli_entrypoint throw(InterruptException())
        """
        proc = run(pipeline(`julia --startup-file=no -e $(interrupt_script)`), wait=false)
        wait(proc)
        @test proc.exitcode == 130
    end

end
