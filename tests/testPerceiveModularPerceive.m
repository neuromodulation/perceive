function testPerceiveModularPerceive(testCase, testFile)
            %for i = 1:numel(testCase.testFiles)
            %    testFile = testCase.testFiles{i};
                % Create two temporary folders
                fix1 = matlab.unittest.fixtures.TemporaryFolderFixture;
                fix2 = matlab.unittest.fixtures.TemporaryFolderFixture;
                testCase.applyFixture(fix1);
                testCase.applyFixture(fix2);

                folder1 = fix1.Folder;
                folder2 = fix2.Folder;

                % Run your functions
                addpath(pwd);
                % Go to folder1
                cd(folder1);
                disp("Now in folder1: " + pwd);
                perceive(testFile);  % Perceive

                cd(folder2);
                disp("Now in folder2: " + pwd);
                perceiveModular(testFile);  % Perceive post-hackathon

                % Compare folder contents
                files1 = dir(fullfile(folder1, '**', '*'));
                files2 = dir(fullfile(folder2, '**', '*'));

                % Filter out directories
                files1 = files1(~[files1.isdir]);
                files2 = files2(~[files2.isdir]);

                % Compare file names
                names1 = sort({files1.name});
                names2 = sort({files2.name});
                testCase.verifyEqual(names1', names2', 'File names differ');

                % Compare file contents
                for k = 1:numel(names1)
                    f1 = fullfile(folder1, names1{k});
                    f2 = fullfile(folder2, names2{k});
                    testCase.verifyTrue(isequal(fileread(f1), fileread(f2)), ...
                        sprintf('File content mismatch: %s', names1{k}));
                end
end