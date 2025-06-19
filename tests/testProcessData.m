classdef testProcessData < matlab.unittest.TestCase
    properties
        testFiles = arrayfun(@(x) sprintf('Report_Json_Session_Report_MOCK%d.json', x), 2:4, 'UniformOutput', false);
        expectedFiles = arrayfun(@(x) sprintf('Report_Json_Session_Report_MOCK%d_GroupHistory.mat', x), 2:4, 'UniformOutput', false);
    end

    methods (Test)
    %         methods (TestMethodSetup)
    %     function setupPath(testCase)
    %         testCase.applyFixture(matlab.unittest.fixtures.PathFixture('path/to/toolbox'));
    %     end
    % end
        function testMultipleFiles(tc)
            %parentDir = fileparts(fileparts(mfilename('fullpath'))); % Move one level up
            %addpath(genpath(parentDir)); % Add parent folder and all its subfolders
            for i = 1:numel(tc.testFiles)
                % Load input file
                actualData = perceive_GroupHistory(tc.testFiles{i});

                % Load expected output
                expectedData = load(tc.expectedFiles{i});

                % Compare actual vs expected data
                tc.verifyEqual(actualData, expectedData, ...
                    sprintf('Mismatch in test file %d', i));

                % Create two temporary folders
                fix1 = matlab.unittest.fixtures.TemporaryFolderFixture;
                fix2 = matlab.unittest.fixtures.TemporaryFolderFixture;
                testCase.applyFixture(fix1);
                testCase.applyFixture(fix2);

                folder1 = fix1.Folder;
                folder2 = fix2.Folder;

                % Run your functions
                perceive(folder1);  % Your first function
                perceiveModular(folder2);  % Your second function

                % Compare folder contents
                files1 = dir(fullfile(folder1, '**', '*'));
                files2 = dir(fullfile(folder2, '**', '*'));

                % Filter out directories
                files1 = files1(~[files1.isdir]);
                files2 = files2(~[files2.isdir]);

                % Compare file names
                names1 = sort({files1.name});
                names2 = sort({files2.name});
                testCase.verifyEqual(names1, names2, 'File names differ');

                % Compare file contents
                for k = 1:numel(names1)
                    f1 = fullfile(folder1, names1{k});
                    f2 = fullfile(folder2, names2{k});
                    testCase.verifyTrue(isequal(fileread(f1), fileread(f2)), ...
                        sprintf('File content mismatch: %s', names1{k}));
                end

            end
        end
    end
end
