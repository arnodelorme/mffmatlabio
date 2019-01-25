% mff_importinfon - import information from MFF 'info.xml' file
%
% Usage:
%   info = mff_exportsignal(mffFile);
%
% Inputs:
%  mffFile - filename/foldername for the MFF file
%
% Output:
%  info   - Matlab structure containing informations contained in the MFF
%           file.

% This file is part of mffmatlabio.
%
% mffmatlabio is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% mffmatlabio is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with mffmatlabio.  If not, see <https://www.gnu.org/licenses/>.

function infoN = mff_importinfon(mffFile, index)

infon = [ 'Info' int2str(index) ];

p = fileparts(which('mff_importsignal.m'));
warning('off', 'MATLAB:Java:DuplicateClass');
javaaddpath(fullfile(p, 'MFF-1.2.2-jar-with-dependencies.jar'));
warning('on', 'MATLAB:Java:DuplicateClass');

mfffactorydelegate = javaObject('com.egi.services.mff.api.LocalMFFFactoryDelegate');
mfffactory         = javaObject('com.egi.services.mff.api.MFFFactory', mfffactorydelegate);

infotype = javaObject('com.egi.services.mff.api.MFFResourceType', javaMethod('valueOf', 'com.egi.services.mff.api.MFFResourceType$MFFResourceTypes', 'kMFF_RT_InfoN'));
info = mfffactory.openResourceAtURI( fullfile(mffFile, [infon  '.xml']), infotype);

infoN = [];
if ~isempty(info) && exist(fullfile(mffFile, [infon  '.xml']))
    if info.loadResource() == true
        
        tmp = info.getInfoNFileType;
        infoN.infoNFileType.value = tmp.getValue;
        
        tmp = info.getInfoNFileTypeInformation;
        try
            infoN.infoNFileTypeInformation.montageName      = char(tmp.getMontageName);
            infoN.infoNFileTypeInformation.sensorLayoutName = char(tmp.getSensorLayoutName);
            infoN.infoNFileTypeInformation.referenceScheme  = char(tmp.getReferenceScheme);
        catch
        end
        try
            infoN.infoNFileTypeInformation.pnsSetName      = char(tmp.getPNSSetName);
        catch
        end
        
        calibAll = info.getCalibrations;
        if ~isempty(calibAll)
            for iCalType = 1:calibAll.size

                calibList = calibAll.get(iCalType-1); % first on the list is Gain
                if strcmpi(char(calibList.getType()), 'GCAL');


                    if ~isempty(calibList)
                        calibValues = [];
                        channels    = calibList.getChannels;

                        for iCalib = 1:channels.size
                            chan = channels.get(iCalib-1);
                            calibValues(iCalib) = str2num(chan.getChannelData());
                        end

                        infoN.calibration = calibValues;

                    end
                end
            end
        end
    else
        fprintf( 'Error: Could not load Info resource; file might be corrupted.\n');
    end
end

mfffactory.closeResource(info);
