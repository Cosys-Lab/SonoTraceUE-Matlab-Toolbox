clear
close all

sendInputSettings = false;
interfaceIP = 'localhost';
interfacePort = 9098;
STUEInterface = sonotraceue.Interface(interfaceIP, interfacePort, sendInputSettings);

plotEnable = true;
plotSensor = true;
dbCutoff = 60;
plotReflectedPoints = true;
plotSpecularSeperate = true;
plotDiffractionSeperate = true;
NumberOfSamplesIRFilter = 256;
IRFilterGaussAlpha = 5;
NumberOfIRSamples = 18000;
ApproximateIRCutDB = -90;
EnableApproximateIR = false;
calculateIR = true;
plotFinalIR = true;
calculatefinalSignals = true;
plotFinalSignals = true;

settings = STUEInterface.receiveSettings();


receivingMeasurements = true;
while receivingMeasurements

    pause(1)
    triggered = STUEInterface.triggerMeasurement();

    if triggered
        [data, type] = STUEInterface.receiveData();
    
        if type == 1
            measurement = data;

            if plotEnable
                measurement.updatePlot(plotSensor, plotReflectedPoints, false, false, dbCutoff)
            end

            pause
    
            if plotSpecularSeperate && measurement.isSpecularSubOutputSet()
                if settings.PointsInSensorFrame
                    measurement.specularSubOutput.updatePlot("Specular Only - Sensor Frame", dbCutoff)
                else
                    measurement.specularSubOutput.updatePlot("Specular Only - World Frame", dbCutoff)
                end
            end

            pause
    
            if plotDiffractionSeperate && measurement.isDiffractionSubOutputSet()
                if settings.PointsInSensorFrame
                    measurement.diffractionSubOutput.updatePlot("Diffraction Only - Sensor Frame", dbCutoff)
                else
                    measurement.diffractionSubOutput.updatePlot("Diffraction Only - World Frame", dbCutoff)
                end
            end

            pause

            if calculateIR
                if measurement.isSpecularSubOutputSet()
                    measurement.specularSubOutput.impulseResponses = sonotraceue.synthetizeIRFromPoints(measurement.specularSubOutput.reflectedPoints, ...
                                                                                                        settings.simSampleRate, NumberOfSamplesIRFilter, settings.frequencies, ...
                                                                                                        IRFilterGaussAlpha, NumberOfIRSamples, settings.numberOfEmitters, ...
                                                                                                        settings.numberOfReceivers, ApproximateIRCutDB, EnableApproximateIR, settings.simSpeedOfSound);
                    if ~measurement.isDiffractionSubOutputSet()
                        measurement.impulseResponses = measurement.specularSubOutput.impulseResponses;
                    end
                end
                if measurement.isDiffractionSubOutputSet()
                    measurement.diffractionSubOutput.impulseResponses = sonotraceue.synthetizeIRFromPoints(measurement.diffractionSubOutput.reflectedPoints, ...
                                                                                                           settings.simSampleRate, NumberOfSamplesIRFilter, settings.frequencies, ...
                                                                                                           IRFilterGaussAlpha, NumberOfIRSamples, settings.numberOfEmitters, ...
                                                                                                           settings.numberOfReceivers, ApproximateIRCutDB, EnableApproximateIR, settings.simSpeedOfSound);
                    if measurement.isSpecularSubOutputSet()
                        measurement.impulseResponses = measurement.diffractionSubOutput.impulseResponses + measurement.specularSubOutput.impulseResponses;
                    else
                        measurement.impulseResponses = measurement.diffractionSubOutput.impulseResponses;
                    end
                end
                
                if plotEnable
                    measurement.updatePlot(false, false, plotFinalIR, false, dbCutoff)
                end
            end

            pause
    
            if calculatefinalSignals && measurement.isImpulseResponsesSet()  
    
                measurement.receiverSignals = sonotraceue.receiverSignalGenerationFromIR(measurement.impulseResponses, settings.emitterSignals{measurement.emitterIndex + 1});
               
                if plotEnable
                    measurement.updatePlot(false, false, false, plotFinalSignals, dbCutoff)
                end
            end

            pause
        elseif type == 0 || type == -1 || type == -2
            receivingMeasurements = false;
        elseif type == 2
            message = data;
            warning("Received a data message out of order.")
        else
            warning("Unknown data type")
            receivingMeasurements = false;
        end
    else
        warning("Could not trigger this time")
    end
end