function inference_generate_submission_file(predictions, record_numbers, epoch_numbers, cfg)
%% Generates a submission CSV file.

% 检查必要字段是否存在
if ~isfield(cfg, 'SUBMISSION_FILE')
    error('Missing field SUBMISSION_FILE in config structure.');
end
if ~isfield(cfg, 'DATA_DIR')
    error('Missing field DATA_DIR in config structure.');
end

fprintf('Generating submission file: %s...\n', cfg.SUBMISSION_FILE);

% Create a table for the submission file
submissionTable = table(record_numbers(:), epoch_numbers(:), predictions(:), ...
    'VariableNames', {'record_number', 'epoch_number', 'label'});

% Define the full path for the submission file
submissionFilePath = fullfile(cfg.DATA_DIR, cfg.SUBMISSION_FILE);

% Write the table to a CSV file
writetable(submissionTable, submissionFilePath);

fprintf('Submission file generated successfully.\n');

end
