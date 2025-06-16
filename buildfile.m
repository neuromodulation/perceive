function plan = buildfile
    import matlab.buildtool.tasks.CodeIssuesTask
    import matlab.buildtool.tasks.TestTask

    plan = buildplan(localfunctions);
    plan("check") = CodeIssuesTask;
    plan("test") = TestTask;
end