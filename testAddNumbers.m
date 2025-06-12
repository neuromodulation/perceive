classdef testAddNumbers < matlab.unittest.TestCase
    methods (Test)
        function testPositiveNumbers(tc)
            result = addNumbers(3, 5);
            tc.verifyEqual(result, 8);
        end

        function testNegativeNumbers(tc)
            result = addNumbers(-3, -5);
            tc.verifyEqual(result, -8);
        end

        function testZero(tc)
            result = addNumbers(0, 0);
            tc.verifyEqual(result, 0);
        end
    end
end