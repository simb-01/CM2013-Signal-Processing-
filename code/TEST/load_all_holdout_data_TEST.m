function Subjects = load_all_holdout_data_TEST(subjects_data, holdout_data_dir, channels)
nrSubjects = numel(subjects_data);
edfFiles = dir(fullfile(holdout_data_dir, '*.edf'));

if isempty(edfFiles)
    error('No EDF files found in folder: %s', holdout_data_dir);
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
    edfPath = fullfile(holdout_data_dir, edfFiles(i).name);
    [multi_channel_data, channel_info] = load_holdout_data_TEST(edfPath, channels);
    subjects_data{i}.ID = i;
    subjects_data{i}.channels = channel_info.labels;
    subjects_data{i}.sampling_rates = channel_info.samples;  % assuming info has field 'samp
    subjects_data{i}.preprocessed_data = multi_channel_data;
end
Subjects = subjects_data;
end



