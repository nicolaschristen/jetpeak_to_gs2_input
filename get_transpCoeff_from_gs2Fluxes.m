%% Compute tansport coefficients, given the turbulent fluxes at several
% raddi, and assuming that the desired transport coefficient are only
% weakly dependent on rotation, rotation shear, temperature and
% density. The transport coefficients are then written to a file.
%
% Input :   ijp --  shot index in JETPEAK DB
%           fname -- name of csv file containing computed fluxes,
%                    see example_files/fluxes.csv for format. The transport
%                    coefficients are saved in the same location as fname,
%                    in a file called 'transportCoeff.csv'
%           jData -- [optional] data structure obtained from JETPEAK, if
%                    read_jData has already been called.
%           trinity_norm -- [optional,0] if true, gs2 flux dotted with gradPsi
%                           else dotted with grad(x).
%
% Ouput:    flx -- table containing fluxes read from fname
%           tCoeff -- table containing the transport coefficients
%
function [flx, tCoeff] = get_transpCoeff_from_gs2Fluxes(ijp, fname, varargin)


% Read optional input arguments
options_default = struct( 'jData', [], ...
                          'trinity_norm', 0 );
opt = get_optargin(options_default, varargin);

%    ------------    %

% Read data for this shot from JETPEAK
if isempty(opt.jData)
    jData = read_jData(ijp, 'trinity_norm', opt.trinity_norm);
else
    jData = opt.jData;
end

%    ------------    %

% Elementary charge
cst.e = 1.602176634e-19;

%    ------------    %

% Read gs2 fluxes from file
flx = read_gs2Fluxes(ijp, fname, 'jData', jData, ...
                                 'trinity_norm', opt.trinity_norm );

%    ------------    %

% Compute transport coefficients

% Momentum pinch [m^2/s]
fac = interpol( ...
    jData.rpsi, ...
    jData.mref*jData.nref.*jData.Rmaj.*abs(jData.omega), ...
    flx.rpsi );
momPinch = -1*flx.PI_noGexb ./ fac;
% Momentum diffusivity [m^2/s]
fac = interpol( ...
    jData.rpsi, ...
    jData.mref.*jData.nref.*jData.Rmaj.^2.*sign(jData.omega).*jData.domega_drpsi, ...
    flx.rpsi );
momDif = -1*(flx.PI-flx.PI_noGexb) ./ fac;
% Ion heat diffusivity [m^2/s]
% TODO: make this expression more precise ?
fac = interpol( ...
    jData.rpsi, ...
    cst.e*jData.nref.*jData.dti_drpsi, ...
    flx.rpsi );
heatDif = -1*flx.Qi ./ fac;

% Write transport coefficients to file
% in same folder as file containing fluxes.
rpsi = flx.rpsi;
tCoeff = table(rpsi, momPinch, momDif, heatDif);
[fpath,~,~] = fileparts(fname);
writetable(tCoeff, [fpath '/transpCoeff.csv']);

end
