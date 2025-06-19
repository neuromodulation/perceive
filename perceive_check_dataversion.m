function config = perceive_check_dataversion(js, config)

    if isfield(js, 'DataVersion')
        assert(strcmp(js.DataVersion, '1.2'), 'Version implentation until 1.2, contact Jojo Vanhoecke for update')
        config.DataVersion = 1.2;
    else
        config.DataVersion = 0;
    end
end