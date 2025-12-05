function Subjects = load_all_data_TEST(subjects_data, training_data_dir, channels)
    nrSubjects = numel(subjects_data);
    edfFiles = dir(fullfile(training_data_dir, '*.edf'));

    if isempty(edfFiles)
        error('No EDF files found in folder: %s', dataDir);
    end

    % --- Sort numerically (fix for R1, R10, R2 issue)
    names = {edfFiles.name};
    nums = zeros(size(names));
    for i = 1:numel(names)
        % Extract numeric part of filename (e.g., R12 -> 12)
        token = regexp(names{i}, '\d+', 'match');
        if ~isempty(token)
            nums(i) = str2double(token{1});
        else
            nums(i) = NaN; % if no digits found
        end
    end
    
    [~, sortIdx] = sort(nums);
    edfFiles = edfFiles(sortIdx);

    for i = 1:nrSubjects
        [~, name, ~] = fileparts(edfFiles(i).name);
        subjects_data{i}.ID = i;

        % --- Load your data here (example using your previous code)
        edfPath = fullfile(training_data_dir, [name '.edf']);
        xmlPath = fullfile(training_data_dir, [name '.xml']);
    
        if isfile(xmlPath)
            [multi_channel_data, labels, info] = load_training_data_TEST(edfPath, xmlPath, channels);
            
            subjects_data{i}.labels = labels;
            subjects_data{i}.channels = info.labels;         % assuming info has field 'labels'
            subjects_data{i}.sampling_rates = info.samples;  % assuming info has field 'samples'
            subjects_data{i}.preprocessed_data = multi_channel_data;
        else
            warning('XML file missing for %s', name);
        end
    end
    Subjects = subjects_data;
end
