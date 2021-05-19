% test_perceive_figure_creation
%
% Test functionality of perceive_figure.
%
% Created by: T.Sieger, 2021-03-15
%
function f = test_perceive_figure_creation()
    global popt;

    close all
    popt=perceive_options();
    popt.maxOpenFigures.total=3;
    popt.maxOpenFigures.testA=2;
    popt.maxOpenFigures.testB=2;

    % open a specific figure of type 'testA'
    disp('== opening testA');
    f1=perceive_figure('testA');
    if popt.rt.openFigures.testA~=1
        error('testA: open #1: popt.rt.openFigures.testA~=1');
    end
    title('testA: 1');
    disp('== opening testA');
    f2=perceive_figure('testA');
    if popt.rt.openFigures.testA~=2
        error('testA: open #2: popt.rt.openFigures.testA~=2');
    end
    if f1==f2
        error(['testA: open #2: f2 of ' num2str(f2) ' = f1 of ' num2str(f1)]);
    end
    title('testA: 2');
    disp('== opening testA');
    f3=perceive_figure('testA');
    % a new figure should not be opened
    if popt.rt.openFigures.testA~=2
        error('testA: open #3: popt.rt.openFigures.testA~=2');
    end
    title('testA: 3');
    if f2~=f3
        error(['testA: open #3: f2 of ' num2str(f2) ' ~= f2 of ' num2str(f3)]);
    end

    % open a specific figure of type 'testB'
    disp('== opening testB');
    g1=perceive_figure('testB');
    if popt.rt.openFigures.testB~=1
        error('testB: open #1: popt.rt.openFigures.testB~=1');
    end
    title('testB: 1');
    disp('== opening testB');
    g2=perceive_figure('testB');
    % a new figure should not be opened
    if popt.rt.openFigures.testB~=1
        error('testB: open #2: popt.rt.openFigures.testB~=1');
    end
    title('testB: 2');
    if g1~=g2
        error(['testB: open #3: g1 of ' num2str(g1) ' ~= g2 of ' num2str(g2)]);
    end

    % open a specific figure of type 'testC'
    disp('== opening testC');
    h1=perceive_figure('testC');
    if h1~=g2
        error('test: h1~=g2');
    end
    title('testC: 1');

    % open a non-specific figure
    disp('== opening figure of non-specific type');
    i1=perceive_figure();
    if popt.rt.openFigures.total~=popt.maxOpenFigures.total
        error('test: popt.rt.openFigures.total~=popt.rt.maxOpenFigures.total');
    end
    if i1~=h1
        error('test: i1~=h1');
    end
    title('test: 1');

    % 3 figures should be opened now

    % close figures
    perceive_figure_close_all();

end
