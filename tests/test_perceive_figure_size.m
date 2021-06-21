% test_perceive_figure_size
%
% Test functionality of perceive_figure: resizing of reused figures.
%
% Created by: T.Sieger, 2021-03-15
%
function f = test_perceive_figure_size()
    global popt;

    close all
    popt=perceive_options();
    popt.maxOpenFigures.total=1;

    % open a non-specific figure
    disp('== opening figure of non-specific type');
    size1=[1 1 40 20];
    f1=perceive_figure('','Units','centimeters','PaperUnits','centimeters','Position',size1);
    if ~all(get(f1,'Position')==size1)
        get(f1,'Position')
        size1
        error('invalid figure size (#1)');
    end

    disp('== opening figure of non-specific type, small size');
    size2=[1 1 20 10];
    f2=perceive_figure('','Units','centimeters','PaperUnits','centimeters','Position',size2);
    if f2~=f1
        error('figure should have been reused');
    end
    if ~all(get(f2,'Position')==size2)
        get(f2,'Position')
        size2
        error('invalid figure size (#2)');
    end

    % close figures
    perceive_figure_close_all();

end
