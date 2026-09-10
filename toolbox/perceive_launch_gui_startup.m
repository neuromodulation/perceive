function perceive_launch_gui_startup()
%PERCEIVE_LAUNCH_GUI_STARTUP Open the App Designer startup UI (perceive_gui_startup).

    perceive_set_dependencies();
    try
        perceive_gui_startup;
    catch ME
        try
            errordlg(ME.message, 'perceive');
        catch %#ok<CTCH>
        end
        rethrow(ME);
    end
end
