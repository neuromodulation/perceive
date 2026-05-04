classdef testProcessData < matlab.unittest.TestCase
    properties
        testFiles = arrayfun(@(x) sprintf('Report_Json_Session_Report_MOCK%d.json', x), 1:16, 'UniformOutput', false);
        expectedFiles = arrayfun(@(x) sprintf('Report_Json_Session_Report_MOCK%d_GroupHistory.mat', x), 1:4, 'UniformOutput', false);
    end

    methods (Test)

        %     function setupPath(testCase)
        %         testCase.applyFixture(matlab.unittest.fixtures.PathFixture('path/to/toolbox'));
        %     end

        function testExpectedAgainstCurrent(testCase)
            %parentDir = fileparts(fileparts(mfilename('fullpath'))); % Move one level up
            %addpath(genpath(parentDir)); % Add parent folder and all its subfolders
            for i = 2:4

                % Load input file
                actualData = perceive_GroupHistory(testCase.testFiles{i});

                % Load expected output
                expectedData = load(testCase.expectedFiles{i});

                % Compare actual vs expected data
                testCase.verifyEqual(actualData, expectedData, ...
                    sprintf('Mismatch in test file %d', i));
            end
        end
        function RunMock1(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{1})
        end

        function RunMock2(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{2})
        end

        function RunMock3(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{3})
        end

        function RunMock4(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{4})
        end

        function RunMock5(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{5})
        end

        function RunMock6(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{6})
        end

        function RunMock7(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{7})
        end

        function RunMock8(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{8})
        end

        function RunMock9(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{9})
        end

        function RunMock10(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{10})
        end

        function RunMock11(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{11})
        end

        function RunMock12(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{12})
        end

        function RunMock13(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{13})
        end

        function RunMock14(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{14})
        end

        function RunMock15(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{15})
        end

        function RunMock16(testCase)
            testPerceiveModularPerceive(testCase, testCase.testFiles{16})
        end


    end
end


