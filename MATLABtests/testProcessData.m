classdef testProcessData %< matlab.unittest.TestCase
    properties
        testFiles = arrayfun(@(x) sprintf('Report_Json_Session_Report_MOCK%d.json', x), 2:3, 'UniformOutput', false);
        expectedFiles = arrayfun(@(x) sprintf('Report_Json_Session_Report_MOCK%d_GroupHistory.mat', x), 2:3, 'UniformOutput', false);
    end

    methods (Test)
        function testMultipleFiles(tc)
            for i = 1:numel(tc.testFiles)
                % Load input file
                actualData = perceive_GroupHistory(tc.testFiles{i});

                % Load expected output
                expectedData = load(tc.expectedFiles{i});

                % Compare actual vs expected data
                tc.verifyEqual(actualData, expectedData, ...
                    sprintf('Mismatch in test file %d', i));
            end
        end
    end
end
