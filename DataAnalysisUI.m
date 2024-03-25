function DataAnalysisUI
    % Create figure window and components
    app = uifigure('Name', 'Custom Data Plotting Interface', 'Position', [200, 200, 800, 600]);
    app.UserData = struct('data', [], 'years', [], 'months', [], 'yearlyGroupCheck', false, 'overlayCheck', false);
    
    % Load Button
    uibutton(app, 'push', 'Text', 'Load Data', 'Position', [20, 420, 100, 22], 'ButtonPushedFcn', @(btn,event)loadData(app));
    
    % Plot
    plotWidth = 600; % Width of the plot
    plotHeight = 400; % Height of the plot
    plotPosition = [150, 100, plotWidth, plotHeight];
    plotAxes = uiaxes(app, 'Position', plotPosition);
    disableDefaultInteractivity(plotAxes); % Disable built-in interactions so that we can apply custom uicontrols
    
    % Grouping Checkbox
    yearlyGroupCheck = uicheckbox(app, 'Text', 'Group by Year', 'Position', [20, 380, 100, 22], 'ValueChangedFcn', @(chk,event)updatePlot(app));
    app.UserData.yearlyGroupCheck = yearlyGroupCheck.Value; % Store initial state
    yearlyGroupCheck.Value = false;  % Ensure it is initially unchecked so that it initially displays data as it is
    
    % Overlay Standard Deviation Checkbox
    overlayCheck = uicheckbox(app, 'Text', 'Overlay ±1σ', 'Position', [20, 325, 100, 22], 'ValueChangedFcn', @(chk,event)updatePlot(app));
    app.UserData.overlayCheck = overlayCheck.Value; % Store initial state
    
    % Zoom Year Selection 
    yearZoomWidth = 60; 
    yearZoomHeight = 22; 
    yearZoomPosition = [50, plotPosition(2) - 30, yearZoomWidth, yearZoomHeight];
    yearZoom = uieditfield(app, 'numeric', 'Position', yearZoomPosition, 'ValueChangedFcn', @(edt,event)updateZoom(edt.Value));

    yearLabelWidth = 100; 
    yearLabelHeight = 22; 
    yearLabelPosition = [50, yearZoomPosition(2) - 30, yearLabelWidth, yearLabelHeight];
    yearLabel = uilabel(app, 'Text', 'Zoom Year:', 'Position', yearLabelPosition);

    % Zoom Slider
    sliderWidth = 450; 
    sliderHeight = 3; 
    sliderPosition = [(plotPosition(1) + plotWidth / 2) - (sliderWidth / 2), plotPosition(2) - 30, sliderWidth, sliderHeight];
    zoomSlider = uislider(app, 'Position', sliderPosition, 'Limits', [0, 99], 'ValueChangedFcn', @(sld,event)updateSlider(sld.Value, yearZoom.Value));
    
    zoomLabelWidth = 100; 
    zoomLabelHeight = 22; 
    zoomLabelPosition = [(plotPosition(1) + plotWidth / 2) - (zoomLabelWidth / 2), sliderPosition(2) - zoomLabelHeight - 30, zoomLabelWidth, zoomLabelHeight];
    sliderLabel = uilabel(app, 'Text', 'Zoom in Plot', 'Position', zoomLabelPosition, 'HorizontalAlignment', 'center');

    % Function to load data
    function loadData(app)
        [filename, path] = uigetfile('*.csv', 'Select the climate data file');
        if filename == 0
            return; 
        end
        
        % Exception handling - pop up window stating error to avoid crashing
        try
            data = readtable(fullfile(path, filename), 'VariableNamingRule', 'preserve');
            app.UserData.data = data;
            app.UserData.years = data.Year;
            app.UserData.months = data{:, 4:end};
            xlabel(plotAxes, 'Years'); 
            ylabel(plotAxes, 'Temperature'); 
            updatePlot(app);
        catch
            uialert(app, ['There is an error with loading data. Please ensure the csv' ...
                'is in the same directory as this file.'], 'Error');
            return;
        end
    end

    % Function to enable dynamically updating the plot
    function updatePlot(app)
        if isempty(app.UserData.data) 
            return;
        end
        
        % Store initial checkbox states
        initialyearlyGroupCheckState = app.UserData.yearlyGroupCheck;
        initialoverlayCheckState = app.UserData.overlayCheck;
    
        % Get checkbox values
        yearlyGroupCheckValue = yearlyGroupCheck.Value;
        overlayCheckValue = overlayCheck.Value;

        % Group by year functionality
        if yearlyGroupCheckValue
            years = unique(app.UserData.years);
            yearlyMeans = zeros(length(years), 1);
            yearlyStd = zeros(length(years), 1);

            for i = 1:length(years)
                yearData = app.UserData.months(app.UserData.years == years(i), :);
                % Calculate the mean and standard deviation while ignoring
                % null values in the csv file so that code doesn't crash
                yearlyMeans(i) = mean(yearData, 'omitnan');
                yearlyStd(i) = std(yearData, 0, 'omitnan');
            end

            xData = years;
            yData = yearlyMeans;
            plotTitle = 'Yearly Averaged Temperature with ±1σ Overlay';
            lineWidth = 2; 

        else
            % Show monthly data
            xData = app.UserData.years;
            yData = app.UserData.months;
            plotTitle = 'Monthly Averaged Temperature over Years';
            lineWidth = 1; 
        end
    
        plot(plotAxes, xData, yData, 'LineWidth', lineWidth);
        grid(plotAxes, 'on'); 
    
        % Overlay ±1σ functionality
        if overlayCheckValue && yearlyGroupCheckValue
            hold(plotAxes, 'on');

            % Iterate over years
            for i = 1:length(years) 
                % Define for the overlay
                x = [xData(i) - 0.5, xData(i) + 0.5, xData(i) + 0.5, xData(i) - 0.5];
                y = [yearlyMeans(i) + yearlyStd(i), yearlyMeans(i) + yearlyStd(i), yearlyMeans(i) - yearlyStd(i), yearlyMeans(i) - yearlyStd(i)];
                
                % Use fill function to achieve area plot shading within the
                % standard deviation values
                fill(plotAxes, x, y, 'b', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
                plot(plotAxes, xData(i), yearlyMeans(i), 'b.'); % Plot mean point Tm
            end
            
            hold(plotAxes, 'off');
        end
        
        % Ensure the plot titles update according to which boxes are checked
        if yearlyGroupCheckValue ~= initialyearlyGroupCheckState || overlayCheckValue ~= initialoverlayCheckState
            if yearlyGroupCheckValue
                if overlayCheckValue
                    plotTitle = 'Yearly Averaged Temperature with ±1σ Overlay';
                else
                    plotTitle = 'Yearly Averaged Temperature over Years';
                end
            % else
            %     if overlayCheckValue
            %         plotTitle = 'Monthly Averaged Temperature with ±1σ Overlay';
            %     else
            %         plotTitle = 'Monthly Averaged Temperature over Years';
            %     end
            end
        end
        title(plotAxes, plotTitle);
        
        % Update stored checkbox states
        app.UserData.yearlyGroupCheck = yearlyGroupCheckValue;
        app.UserData.overlayCheck = overlayCheckValue;
    end


    % Update zooming functionality
    function updateZoom(zoomYear)
        zoomWidth = 100;  
        set(plotAxes, 'XLim', [zoomYear - zoomWidth/2, zoomYear + zoomWidth/2]);
    end

    % Update zooming functionality
    function updateSlider(zoomPercent, zoomYear)
        zoomWidth = 100 - zoomPercent;
        set(plotAxes, 'XLim', [zoomYear - zoomWidth/2, zoomYear + zoomWidth/2]);
    end
end
