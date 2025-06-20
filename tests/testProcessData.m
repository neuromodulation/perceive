classdef testProcessData < matlab.unittest.TestCase
    properties
        testFiles = arrayfun(@(x) sprintf('Report_Json_Session_Report_MOCK%d.json', x), 2:4, 'UniformOutput', false);
        expectedFiles = arrayfun(@(x) sprintf('Report_Json_Session_Report_MOCK%d_GroupHistory.mat', x), 2:4, 'UniformOutput', false);
    end

    methods (Test)

        %     function setupPath(testCase)
        %         testCase.applyFixture(matlab.unittest.fixtures.PathFixture('path/to/toolbox'));
        %     end

        function testExpectedAgainstCurrent(testCase)
            %parentDir = fileparts(fileparts(mfilename('fullpath'))); % Move one level up
            %addpath(genpath(parentDir)); % Add parent folder and all its subfolders
            for i = 1:numel(testCase.testFiles)

                % Load input file
                actualData = perceive_GroupHistory(testCase.testFiles{i});

                % Load expected output
                expectedData = load(testCase.expectedFiles{i});

                % Compare actual vs expected data
                testCase.verifyEqual(actualData, expectedData, ...
                    sprintf('Mismatch in test file %d', i));
            end
        end
        function RunMock2(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{2})
        end

        function RunMock3(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{3})
        end
        
    end
end


