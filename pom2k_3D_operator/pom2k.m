clear all;

global im jm kb imm1 imm2 jmm1 jmm2 kbm1 kbm2 kl1 kl2 ...
    z zz dz dzz z_3d zz_3d dz_3d dzz_3d ...
    dx dy art aru arv  fsm dum dvm ...
    dx_3d dy_3d art_3d aru_3d arv_3d fsm_3d dum_3d dvm_3d;

global small pi netcdf_file iproblem mode nadv nitera ...
     sw nread dte isplit days prtd1 prtd2 swtch iskp jskp ...
     lramp rhoref tbias sbias grav kappa z0b cbcmin cbcmax...
     horcon tprni umol hmax vmaxl slmax ntp nbct nbcs ispadv...
     smoth alpha dti dte2 dti2 iend iprint iswtch ispi isp2i;
 
im=65; jm=49; kb=21;
imm1=im-1; imm2=im-2; jmm1=jm-1; jmm2=jm-2; kbm1=kb-1; kbm2=kb-2;

alpha          =0.0;dte            =0.0;dti            =0.0;dti2           =0.0;
grav           =0.0;hmax           =0.0;kappa          =0.0;pi             =0.0;
ramp           =0.0;rfe            =0.0;rfn            =0.0;rfs            =0.0;
rfw            =0.0;rhoref         =0.0;sbias          =0.0;slmax          =0.0;
small          =0.0;tbias          =0.0;time           =0.0;tprni          =0.0;
umol           =0.0;vmaxl 		    =0.0;

iint           =0;iprint         =0;iskp           =0;jskp         =0;
kl1            =0;kl2            =0;mode           =0;ntp			=0;

%     Integers defining the number of logarithmic layers at the
%     surface and bottom (used by subroutine depth). The number of
%     logarithmic layers are kl1-2 at the surface and kb-kl2-1
%     at the bottom. For no log portions, set kl1=2 and kl2=kb-1:
kl1=6;
kl2=kb-2;

source='pom2k  2006-05-03';

small=1.e-9;          							% Small value

pi=atan(1.0)*4.0;    							% PI

title='Run 1'; 									% run's title

netcdf_file='pom2k.nc';  						% netCDF output file

%     Problem number:
%     iproblem      problem      initialisation
%                    type          subroutine
%         1        seamount       seamount
%         2        conservation   box
%                  box
%         3        IC from file   file2ic
iproblem=1;

%       mode                     description
%        2        2-D calculation (bottom stress calculated in advave)
%        3        3-D calculation (bottom stress calculated in profu,v)
%        4        3-D calculation with t and s held fixed
mode=3;

%     Advection scheme:
%      nadv     Advection scheme
%        1       Centred scheme, as originally provide in POM
%        2       Smolarkiewicz iterative upstream scheme, based on
%                subroutines provided by Gianmaria Sannino and Vincenzo
%                Artale
nadv=1;

%     Constants for Smolarkiewicz iterative upstream scheme.
%
%     Number of iterations. This should be in the range 1 - 4. 1 is
%     standard upstream differencing; 3 adds 50% CPU time to POM:
nitera=2;

%     Smoothing parameter. This should preferably be 1, but 0 < sw < 1
%     gives smoother solutions with less overshoot when nitera > 1:
sw=0.50;

%     Index to indicate whether run to start from restart file
%     (nread=0: no restart input file; nread=1: restart input file):
nread=0;

%     External (2-D) time step (secs.) according to CFL:
dte=6.0;

%     <Internal (3-D) time step>/<External (2-D) time step> (dti/dte; dimensionless):
isplit=30;

%     Date and time of start of initial run of model in format (i.e. UDUNITS convention)
%
%       YYYY-MM-DD HH:MM:SS <+/->HH:MM
%
%     where "<+/->HH:MM" is the time zone (positive eastwards from
%     Coordinated Universal Time). NOTE that the climatological time
%     axis (i.e. beginning of year zero, which does not exist in the
%     real-world calendar) has been used here. Insert your own date
%     and time as required:
time_start='2000-01-01 00:00:00 +00:00';


%days=0.025;       % run duration in days
days=1.5;       % run duration in days

prtd1=0.0125;     % Initial print interval (days)

prtd2=1.0;         % Final print interval (days)

swtch=1000.0;      % Time to switch from prtd1 to prtd2

iskp=4;             % Printout skip interval in i

jskp=3;             % Printout skip interval in j

%     Logical for inertial ramp (true if inertial ramp to be applied
%     to wind stress and baroclinic forcing, otherwise false)
lramp=false;

%     Reference density (recommended values: 1025 for seawater, 1000 for freswater; S.I. units):
rhoref=1025.0;

tbias=0.0;         % Temperature bias (deg. C)

sbias=0.0;         % Salinity bias

grav=9.8060;       % gravity constant (S.I. units)

kappa=0.40;        % von Karman's constant

z0b=.010;          % Bottom roughness (metres)

cbcmin=.00250;     % Minimum bottom friction coeff.

cbcmax=1.0;        % Maximum bottom friction coeff.

horcon=0.20;       % Smagorinsky diffusivity coeff.

%     Inverse horizontal turbulent Prandtl number (ah/am; dimensionless):
%
%     NOTE that tprni=0.0 yields zero horizontal diffusivity!
tprni=.20;

%     Background viscosity used in subroutines profq, proft, profu and profv (S.I. units):
umol=2.e-5;

%     Maximum depth used in radiation boundary condition in subroutine bcond (metres):
hmax=4500.0;

%     Maximum magnitude of vaf (used in check that essentially tests for CFL violation):
vmaxl=100.0;

%     Maximum allowable value of:
%
%       <difference of depths>/<sum of depths>
%
%     for two adjacent cells (dimensionless). This is used in subroutine
%     slpmax. If >= 1, then slpmax is not applied:
slmax=2.0;


%     Water type, used in subroutine proft.
%       ntp    Jerlov water type
%        1            i
%        2            ia
%        3            ib
%        4            ii
%        5            iii
ntp=2;

%     Surface temperature boundary condition, used in subroutine proft:
%       nbct   prescribed    prescribed   short wave
%              temperature      flux      penetration
%        1        no           yes           no
%        2        no           yes           yes
%        3        yes          no            no
%        4        yes          no            yes
%
nbct=1;

%     Surface salinity boundary condition, used in subroutine proft:
%       nbcs   prescribed    prescribed
%               salinity      flux
%        1        no           yes
%        3        yes          no
%     NOTE that only 1 and 3 are allowed for salinity.
nbcs=1;

%     Step interval during which external (2-D) mode advective terms are
%     not updated (dimensionless):
ispadv=5;

%     Constant in temporal filter used to prevent solution splitting
%     (dimensionless):
smoth=0.100;

%     Weight used for surface slope term in external (2-D) dynamic
%     equation (a value of alpha = 0.0 is perfectly acceptable, but the
%     value, alpha=.2250 permits a longer time step):
alpha=0.2250;

%     Initial value of aam:
aam_init=500.0;

% ramp is not assigned in fortran pom2k before used in barop
ramp=0.0;

tatm = 0.0;
satm = 0.0;
io = zeros(100);
jo = zeros(100);
ko = zeros(100);

%     End of input of constants
%***********************************************************************


%     Calculate some constants:
dti=dte*isplit;

dte2=dte*2;
dti2=dti*2;
iend=max(floor(days*24.0*3600.0/dti+0.5),2);

iprint=floor(prtd1*24.0*3600.0/dti+0.5);
iswtch=floor(swtch*24.0*3600.0/dti+0.5);

ispi=1.0/isplit;
isp2i=1.0/(2.0*isplit);
     
aam2d=zeros(im,jm)   ;advua=zeros(im,jm)   ;advva=zeros(im,jm)   ;adx2d=zeros(im,jm)   ;
ady2d=zeros(im,jm)   ;art=zeros(im,jm)     ;aru=zeros(im,jm)     ;arv=zeros(im,jm)     ;
cbc=zeros(im,jm)     ;cor=zeros(im,jm)     ;d=zeros(im,jm)       ;drx2d=zeros(im,jm)   ;
dry2d=zeros(im,jm)   ;dt=zeros(im,jm)      ;dum=zeros(im,jm)     ;dvm=zeros(im,jm)     ;
dx=zeros(im,jm)      ;dy=zeros(im,jm)      ;east_c=zeros(im,jm)  ;east_e=zeros(im,jm)  ;
east_u=zeros(im,jm)  ;east_v=zeros(im,jm)  ;e_atmos=zeros(im,jm) ;egb=zeros(im,jm)     ;
egf=zeros(im,jm)     ;el=zeros(im,jm)      ;elb=zeros(im,jm)     ;elf=zeros(im,jm)     ;
et=zeros(im,jm)      ;etb=zeros(im,jm)     ;etf=zeros(im,jm)     ;fluxua=zeros(im,jm)  ;
fluxva=zeros(im,jm)  ;fsm=zeros(im,jm)     ;h=zeros(im,jm)       ;north_c=zeros(im,jm) ;
north_e=zeros(im,jm) ;north_u=zeros(im,jm) ;north_v=zeros(im,jm) ;psi=zeros(im,jm)     ;
rot=zeros(im,jm)     ;ssurf=zeros(im,jm)   ;swrad=zeros(im,jm)   ;vfluxb=zeros(im,jm)  ;
tps=zeros(im,jm)     ;tsurf=zeros(im,jm)   ;ua=zeros(im,jm)      ;vfluxf=zeros(im,jm)  ;
uab=zeros(im,jm)     ;uaf=zeros(im,jm)     ;utb=zeros(im,jm)     ;utf=zeros(im,jm)     ;
va=zeros(im,jm)      ;vab=zeros(im,jm)     ;vaf=zeros(im,jm)     ;
vtb=zeros(im,jm)     ;vtf=zeros(im,jm)     ;wssurf=zeros(im,jm)  ;wtsurf=zeros(im,jm)  ;
wubot=zeros(im,jm)   ;wusurf=zeros(im,jm)  ;wvbot=zeros(im,jm)   ;wvsurf=zeros(im,jm)  ;
wubot1=zeros(im,jm)  ;wvbot1=zeros(im,jm)  ;

aam=zeros(im,jm,kb)  ;advx=zeros(im,jm,kb) ;advy=zeros(im,jm,kb) ;a=zeros(im,jm,kb)    ;
c=zeros(im,jm,kb)    ;drhox=zeros(im,jm,kb);drhoy=zeros(im,jm,kb);dtef=zeros(im,jm,kb) ;
ee=zeros(im,jm,kb)   ;gg=zeros(im,jm,kb)   ;kh=zeros(im,jm,kb)   ;km=zeros(im,jm,kb)   ;
kq=zeros(im,jm,kb)   ;l=zeros(im,jm,kb)    ;q2b=zeros(im,jm,kb)  ;q2=zeros(im,jm,kb)   ;
q2lb=zeros(im,jm,kb) ;q2l=zeros(im,jm,kb)  ;rho=zeros(im,jm,kb)  ;rmean=zeros(im,jm,kb);
sb=zeros(im,jm,kb)   ;sclim=zeros(im,jm,kb);s=zeros(im,jm,kb)    ;tb=zeros(im,jm,kb)   ;
tclim=zeros(im,jm,kb);t=zeros(im,jm,kb)    ;ub=zeros(im,jm,kb)   ;uf=zeros(im,jm,kb)   ;
u=zeros(im,jm,kb)    ;vb=zeros(im,jm,kb)   ;vf=zeros(im,jm,kb)   ;v=zeros(im,jm,kb)    ;
w=zeros(im,jm,kb)    ;zflux=zeros(im,jm,kb);

ele=zeros(1,jm)      ;eln=zeros(1,im)      ;els=zeros(1,im)      ;elw=zeros(1,jm)      ;
sbe=zeros(jm,kb)     ;sbn=zeros(im,kb)     ;sbs=zeros(im,kb)     ;sbw=zeros(jm,kb)     ;
tbe=zeros(jm,kb)     ;tbn=zeros(im,kb)     ;tbs=zeros(im,kb)     ;tbw=zeros(jm,kb)     ;
uabe=zeros(1,jm)     ;uabw=zeros(1,jm)     ;ube=zeros(jm,kb)     ;ubw=zeros(jm,kb)     ;
vabn=zeros(1,im)     ;vabs=zeros(1,im)     ;vbn=zeros(im,kb)     ;vbs=zeros(im,kb)     ;

d_3d=zeros(im,jm,kb) ;dt_3d=zeros(im,jm,kb);

if(iproblem ~= 3)
    [z,zz,dz,dzz,z_3d,zz_3d,dz_3d,dzz_3d]=new_depth(im, jm, kb, kl1, kl2);
end

global OP
OP = new_operator(im,jm,kb);

% [OP_AXF, OP_AXB, OP_AYF, OP_AYB, OP_AZF, OP_AZB, ...
%  OP_DXF, OP_DXB, OP_DYF, OP_DYB, OP_DZF, OP_DZB, ...
%  OP_L_XY,   OP_L_XZ,   OP_L_YZ, ...
%  OP_R_XY,   OP_R_XZ,   OP_R_YZ, ...
%  OP_SUMZ1, OP_SUMZ2] = new_operator(im,jm,kb);

% save('grid.mat','im','jm','kb','imm1','imm2','jmm1','jmm2','kbm1','kbm2','kl1','kl2',...
%                 'z','zz','dz','dzz','z_3d','zz_3d','dz_3d','dzz_3d');
% save('para.mat','small','pi','netcdf_file','iproblem','mode','nadv','nitera',...
%      'sw','nread','dte','isplit','days','prtd1','prtd2','swtch','iskp','jskp',...
%      'lramp','rhoref','tbias','sbias','grav','kappa','z0b','cbcmin','cbcmax',...
%      'horcon','tprni','umol','hmax','vmaxl','slmax','ntp','nbct','nbcs','ispadv',...
%      'smoth','alpha','dti','dte2','dti2','iend','iprint','iswtch','ispi','isp2i');

% save('operator.mat',...
% 'OP_AXF', 'OP_AXB', 'OP_AYF', 'OP_AYB', 'OP_AZF', 'OP_AZB', ...
% 'OP_DXF', 'OP_DXB', 'OP_DYF', 'OP_DYB', 'OP_DZF', 'OP_DZB', ...
% 'OP_L_XY',    'OP_L_XZ',   'OP_L_YZ', ...                  
% 'OP_R_XY',    'OP_R_XZ',   'OP_R_YZ', ...                  
% 'OP_SUMZ1',   'OP_SUMZ2');


if(iproblem == 1)
    [dx,dy,cor,...
        east_c,north_c,east_e,north_e,east_u,north_u,east_v,north_v,...
        h,art,aru,arv,fsm,dum,dvm,...
        tb,sb,tclim,sclim,ub,uab,elb,etb,dt,...
        aam2d,rho,rmean,rfe,rfw,rfn,rfs,...
        uabw,uabe,ele,elw,tbe,tbw,sbe,sbw,tbn,tbs,sbn,sbs, ...
        dx_3d,dy_3d,cor_3d, ...
        h_3d,art_3d,aru_3d,arv_3d, ...
        fsm_3d,dum_3d,dvm_3d,dt_3d] = new_seamount(e_atmos,aam);
   
elseif(iproblem == 2)
   [dx,dy,cor,...
        east_c,north_c,east_e,north_e,east_u,north_u,east_v,north_v,...
        h,art,aru,arv,fsm,dum,dvm,...
        tb,sb,tclim,sclim,ub,uab,elb,etb,dt,...
        aam2d,rho,rmean,rfe,rfw,rfn,rfs,...
        uabw,uabe,ele,elw,tbe,tbw,sbe,sbw,tbn,tbs,sbn,sbs,rot,tatm,satm,vfluxf,tbias,sbias] = box(dx,dy,cor,...
        east_c,north_c,east_e,north_e,east_u,north_u,east_v,north_v,...
        h,art,aru,arv,fsm,dum,dvm,...
        tb,sb,tclim,sclim,ub,uab,elb,etb,dt,...
        aam2d,rho,rmean,rfe,rfw,rfn,rfs,...
        uabw,uabe,ele,elw,tbe,tbw,sbe,sbw,tbn,tbs,sbn,sbs,...
        e_atmos,aam,im,jm,kb,imm1,jmm1,kbm1,slmax,zz,tbias,sbias,grav,rhoref,rot,tatm,satm,vfluxf);
     
elseif(iproblem ==3)
    [dx,dy,cor,...
    east_c,north_c,east_e,north_e,east_u,north_u,east_v,north_v,...
    h,art,aru,arv,fsm,dum,dvm,...
    tb,sb,tclim,sclim,ub,uab,elb,etb,dt,...
    aam2d,rho,rmean,rfe,rfw,rfn,rfs,...
    uabw,uabe,ele,elw,tbe,tbw,sbe,sbw,tbn,tbs,sbn,sbs,rot,els,eln,vabs,vabn,ubw,ube,vbs,vbn] = file2ic(dx,dy,cor,...
    east_c,north_c,east_e,north_e,east_u,north_u,east_v,north_v,...
    h,art,aru,arv,fsm,dum,dvm,...
    tb,sb,tclim,sclim,ub,uab,elb,etb,dt,...
    aam2d,rho,rmean,rfe,rfw,rfn,rfs,...
    uabw,uabe,ele,elw,tbe,tbw,sbe,sbw,tbn,tbs,sbn,sbs,...
    e_atmos,aam,im,jm,kb,imm1,jmm1,kbm1,slmax,zz,tbias,sbias,grav,rhoref,rot,els,eln,vabs,vabn,ubw,ube,vbs,vbn);
    
else
    fprintf('Invalid value of iproblem ..... program terminated\n');
    return
end

% save('grid.mat','im','jm','kb','imm1','imm2','jmm1','jmm2','kbm1','kbm2','kl1','kl2',...
%                 'z','zz','dz','dzz','z_3d','zz_3d','dz_3d','dzz_3d',...
%                 'dx','dy','dz','art','aru','arv','art','aru','arv','fsm','dum','dvm',...
%                 'dx_3d','dy_3d','art_3d','aru_3d','arv_3d','art_3d','aru_3d','arv_3d','fsm_3d','dum_3d','dvm_3d');

%     Inertial period for temporal filter:
period=(2.0*pi)/abs(cor(floor(im/2),floor(jm/2)))/86400.0;

%     Initialise time:
time0=0.0;
time=0.0;
%     Initial conditions:
%     NOTE that lateral thermodynamic boundary conditions are often set
%     equal to the initial conditions and are held constant thereafter.
%    Users can of course create variable boundary conditions.

ua=uab;
va=vab;
el=elb;
et=etb;
etf=et;
d=h + el;
dt=h + et;
w(:,:,1)=vfluxf;

d_3d=repmat(d,1,1,kb);
dt_3d=repmat(dt,1,1,kb);


l           = 0.1*dt_3d;
q2b(:,:,:)  = small;
q2lb        = l.*q2b;
kh          = l.*sqrt(q2b);
km          = kh;
kq          = kh;
aam(:,:,:)= aam_init;

q2 =q2b;
q2l=q2lb;
t  =tb;
s  =sb;
u  =ub;
v  =vb;

[rho]=new_dens(s,t,h_3d,fsm_3d);

%[rho,drhox,drhoy] =baropg(rho,drhox,drhoy,im,jm,imm1,jmm1,kb,kbm1,grav,zz,dt,dum,dvm,ramp,rmean,dx,dy);                       
[rho,drhox,drhoy] = new_baropg(rho, rmean, dt, ramp);

for k=1:kbm1
    drx2d=drx2d+drhox(:,:,k)*dz(k);
    dry2d=dry2d+drhoy(:,:,k)*dz(k);
end

%     Calculate bottom friction coefficient:
cbc=(kappa./log((1.0+zz(kbm1))*h/z0b)).^2;
cbc=max(cbcmin,cbc);
%     If the following is invoked, then it is probable that the wrong
%     choice of z0b or vertical spacing has been made:
cbc=min(cbcmax,cbc);

%
%     Calculate external (2-D) CFL time step:
tps=0.5./sqrt(1.0./dx.^2+1.0./dy.^2) ./ sqrt(grav*(h+small)) .* fsm;

d = h+el;
dt = h+et;
time = time0;

d_3d=repmat(d,1,1,kb);
dt_3d=repmat(dt,1,1,kb);

%==========================================
%           begin internal (3-D) mode
%==========================================
for iint=1:iend
    time=dti*iint*1.0/86400.0+time0;
    if(lramp~=0)
        ramp = time/period;
        if(ramp>1.0)
            ramp=1.0;
        end
    else
        ramp=1.0;
    end

    %       write(6,2) mode,iint,time
    %   2   format(' mode,iint,time =',2i5,f9.2)
    %-----------------------------------------------------------------------
    %     Set time dependent, surface and lateral boundary conditions.
    %     The latter will be used in subroutine bcond. Users may
    %     wish to create a subroutine to supply wusurf, wvsurf, wtsurf,
    %     wssurf, swrad and vflux.
    %
    %     Introduce simple wind stress. Value is negative for westerly or
    %     southerly winds. The following wind stress has been tapered
    %     along the boundary to suppress numerically induced oscilations
    %     near the boundary (Jamart and Ozer, J.G.R., 91, 10621-10631).
    %     To make a healthy surface Ekman layer, it would be well to set
    %     kl1=9.
    %
    for j=2:jmm1
        for i=2:imm1
            if(iproblem~=3) % constant wind read in file2ic
                
    %           wusurf(i,j)=ramp*(1.e-4*cos(pi*(j-1)/jmm1));
                wusurf(i,j)=1.00*(1.e-4*cos(pi*(j-1)/jmm1))  ...
                    *0.25*(dvm(i,j+1)+dvm(i-1,j+1)     ...
                    +dvm(i-1,j)+dvm(i,j));
                % --- no wind ----
                %           wusurf(i,j)=0.e0;
                wvsurf(i,j)=0.e0;
            end
            
            e_atmos(i,j)=0.e0;
            vfluxf(i,j)=0.e0;
            %
            %     Set w(i,j,1)=vflux(i,j).ne.0 if one wishes non-zero flow across
            %     the sea surface. See calculation of elf(i,j) below and subroutines
            %     vertvl, advt1 (or advt2). If w(1,j,1)=0, and, additionally, there
            %     is no net flow across lateral boundaries, the basin volume will be
            %     constant; if also vflux(i,j).ne.0, then, for example, the average
            %     salinity will change and, unrealistically, so will total salt.
            %
            w(i,j,1)=vfluxf(i,j);
            %
            %     Set wtsurf to the sensible heat, the latent heat (which involves
            %     only the evaporative component of vflux) and the long wave
            %     radiation:
            %
            wtsurf(i,j)=0.0;
            %
            %     Set swrad to the short wave radiation:
            %
            swrad(i,j)=0.0;
            %
            %     To account for change in temperature of flow crossing the sea
            %     surface (generally quite small compared to latent heat effect)
            %
            tatm=t(i,j,1)+tbias;    % an approximation
            wtsurf(i,j)=wtsurf(i,j)+vfluxf(i,j)*(tatm-t(i,j,1)-tbias);
            %
            %     Set the salinity of water vapor/precipitation which enters/leaves
            %     the atmosphere (or e.g., an ice cover)
            %
            satm=0.0  ;
            wssurf(i,j)=  vfluxf(i,j)*(satm-s(i,j,1)-sbias)  ;
            %
        end
    end
    %
    %-----------------------------------------------------------------------
    %
    %     Set lateral viscosity:
    %
    %     If mode=2 then initial values of aam2d are used. If one wishes
    %     to use Smagorinsky lateral viscosity and diffusion for an
    %     external (2-D) mode calculation, then appropiate code can be
    %     adapted from that below and installed just before the end of the
    %     "if(mode.eq.2)" loop in subroutine advave.
    %
    %     %alculate Smagorinsky lateral viscosity:
    %
    %       ( hor visc = horcon*dx*dy*sqrt((du/dx)**2+(dv/dy)**2
    %                                     +.5*(du/dy+dv/dx)**2) )
    %

    if(mode~=2)
% % %  [advx,advy]=advct(u,v,dx,dy,dt,aam,ub,vb,aru,arv,im,jm,kb,imm1,jmm1,kbm1);
        [advx,advy]=new_advct(u,v,dt_3d,aam,ub,vb);        
% % %         [rho,drhox,drhoy] = baropg(rho,drhox,drhoy,...
% % %             im,jm,imm1,jmm1,kb,kbm1,grav,...
% % %             zz,dt,dum,dvm,ramp,rmean,dx,dy);   
        [rho,drhox,drhoy] = new_baropg(rho, rmean, dt, ramp);   
     
        aam=horcon .* dx_3d .* dy_3d .*sqrt( (DXF(u)./dx_3d).^2 + (DYF(v)./dy_3d).^2    ...
                +0.5*( DYB(AYF(AXF(u)))./dy_3d + DXB(AXF(AYF(v)))./dx_3d).^2 );
        aam(:,1,:)=aam_init;
        aam(:,jm,:)=aam_init;
        aam(1,:,:)=aam_init;
        aam(im,:,:)=aam_init;
        aam(:,:,kb)=aam_init;

        %     Form vertical averages of 3-D fields for use in external (2-D)
        %     mode:
        
%         adx2d=zeros(im,jm);
%         ady2d=zeros(im,jm);
%         drx2d=zeros(im,jm);
%         dry2d=zeros(im,jm);
%         aam2d=zeros(im,jm);
%         
%         for k=1:kb
%             adx2d=adx2d+advx(:,:,k)*dz(k);
%             ady2d=ady2d+advy(:,:,k)*dz(k);
%             drx2d=drx2d+drhox(:,:,k)*dz(k);
%             dry2d=dry2d+drhoy(:,:,k)*dz(k);
%             aam2d=aam2d+aam(:,:,k)*dz(k);
%         end

        adx2d = sum(advx.*dz_3d, 3);
        ady2d = sum(advy.*dz_3d, 3);
        drx2d = sum(drhox.*dz_3d, 3);
        dry2d = sum(drhoy.*dz_3d, 3);
        aam2d = sum(aam.*dz_3d, 3);
        
        %[tps2,advua,advva,fluxua,fluxva,wubot,wvbot,tps0] = advave(tps,advua,advva,fluxua,fluxva,wubot,wvbot,tps,...
        %    mode,im,jm,imm1,jmm1,aam2d,...
        %    uab,vab,dx,dy,ua,va,cbc,aru,arv,d);
        [tps,wubot,wvbot,advua,advva] = new_advave(tps,wubot,wvbot,mode,aam2d,uab,vab,ua,va,cbc,d);
        
        adx2d=adx2d-advua;
        ady2d=ady2d-advva;
    end
    
    egf=el*ispi;
    
    utf=ua .* 2.0 .* AXB(d) .* isp2i;
    vtf=va .* 2.0 .* AYB(d) .* isp2i;
    
    %----------------------------------------------------------------------    
    for iext=1:isplit    % Begin external (2-D) mode        
        %
        %     NOTE addition of surface freshwater flux, w(i,j,1)=vflux, compared
        %     with pom98.f. See also modifications to subroutine vertvl.
        %   
        elf= elb+dte2.*(-(DXF( AXB(d).*AXB(dy).*ua)+DYF(AYB(d).*AYB(dx).*va))./ art-vfluxf);  
        
        [elf,uaf,vaf,uf,vf,w] = new_bcond(1,elf,uaf,vaf,uf,vf,w,...
            im,jm,kb,imm1,jmm1,kbm1,...
            fsm,grav,ramp,rfe,h,uabe,ele,el,uabw,rfw,elw,rfn,eln,vabs,rfs,els,...
            dum,dvm,hmax,u,v,t,s,tbn,sbn,dti,tbs,sbs,q2,q2l,small,vabn,dx,dy,dt,tbe,sbe,tbw,sbw,zz);
        
        if(mod(iext,ispadv)==0)
% % %             [tps2,advua,advva,fluxua,fluxva,wubot,wvbot,tps0] = advave(tps,advua,advva,fluxua,fluxva,wubot,wvbot,tps,...
% % %                 mode,im,jm,imm1,jmm1,aam2d,...
% % %                 uab,vab,dx,dy,ua,va,cbc,aru,arv,d);
            [tps,wubot,wvbot,advua,advva] = new_advave(tps,wubot,wvbot,mode,aam2d,uab,vab,ua,va,cbc,d); 
        end
    
        uaf=   DIVISION( (2.0*AXB(h+elb) .* aru .* uab ...
               -4.0* dte .* (adx2d + advua - aru .* AXB(cor .* d .* AYF(va)) ...
               + grav .* AXB(dy) .* AXB(d)  ...
                 .*( (1.0-2.0*alpha) .* DXB(el) + alpha* (DXB(elb)+ DXB(elf)) + DXB(e_atmos) ) ...
               + drx2d + aru .* (wusurf-wubot))) , (2.0*AXB(h+elf) .* aru));      
               
        vaf=   DIVISION( (2.0*AYB(h+elb) .* arv .* vab ...
               -4.0* dte .* (ady2d + advva + arv .* AYB(cor .* d .* AXF(ua)) ...
               + grav .* AYB(dx) .* AYB(d)  ...
                 .*( (1.0-2.0*alpha) .* DYB(el) + alpha* (DYB(elb)+ DYB(elf)) + DYB(e_atmos) ) ...
               + dry2d + arv .* (wvsurf-wvbot))) , (2.0*AYB(h+elf) .* arv));  

        [elf,uaf,vaf,uf,vf,w] = new_bcond(2,elf,uaf,vaf,uf,vf,w,...
            im,jm,kb,imm1,jmm1,kbm1,...
            fsm,grav,ramp,rfe,h,uabe,ele,el,uabw,rfw,elw,rfn,eln,vabs,rfs,els,...
            dum,dvm,hmax,u,v,t,s,tbn,sbn,dti,tbs,sbs,q2,q2l,small,vabn,dx,dy,dt,tbe,sbe,tbw,sbw,zz);
        
        if(iext==(isplit-2))
            etf=0.25*smoth*elf;
        elseif(iext==(isplit-1))
            etf=etf+0.5*(1.0-0.5*smoth)*elf;
        elseif(iext==isplit)
            etf=(etf+0.5*elf).*fsm;
        end
         
        % Stop if velocity condition violated (generally due to CFL
        % criterion not being satisfied):   
        
%        vamax=0.0;       
%         for j=1:jm
%             for i=1:im
%                 if(abs(vaf(i,j))>=vamax)
%                     vamax=abs(vaf(i,j));
%                     imax=i;
%                     jmax=j;
%                 end
%             end
%         end
        
        [vamax, vapos]=max(abs(vaf(:)));
        [imax, jmax]=ind2sub(size(vaf), vapos);
%         fprintf('diff_vmax:%.18f\n', vamax-vamax);
%         fprintf('diff_imax:%d\n', imax1-imax);
%         fprintf('diff_jmax:%d\n', jmax1-jmax);
        
        if(vamax<=vmaxl)
            %
            %     Apply filter to remove time split and reset time sequence:
            %
            ua=ua+0.5*smoth*(uab-2.0*ua+uaf);
            va=va+0.5*smoth*(vab-2.0*va+vaf);
            el=el+0.5*smoth*(elb-2.0*el+elf);
            elb=el;
            el=elf;
            d=h+el;
            uab=ua;
            ua=uaf;
            vab=va;
            va=vaf;
            
            if(iext~=isplit)
                egf=egf+el*ispi;
                utf=utf+2.0* ua .* AXB(d) * isp2i;
                vtf=vtf+2.0* va .* AYB(d) * isp2i;
            end
        end
    end
    
    %===========================================
    %End of external (2-D) mode
    %=============================================
    
    if(vamax<=vmaxl) 
        %
        %     continue with internal (3-D) mode calculation:
        %
        if((iint~= 1|| time0~=0.e0) && mode~=2)
            %
            %     Adjust u(z) and v(z) such that depth average of (u,v) = (ua,va):
            %
%             tps=zeros(im,jm);
%             for k=1:kbm1
%                 tps=tps+u(:,:,k)*dz(k);
%             end
%?
            tps=sum(u(:,:,1:kbm1).*dz_3d(:,:,1:kbm1), 3);
            
%             for k=1:kbm1
%                 u(:,:,k)=(u(:,:,k)-tps)+   DIVISION((utb+utf), 2.0*AXB(dt));
%             end
            
            utb_3d = repmat(utb, 1, 1, kbm1);
            utf_3d = repmat(utf, 1, 1, kbm1);
            tps_3d = repmat(tps, 1, 1, kbm1);
            dt_3d1 = repmat(dt, 1, 1, kbm1);
            dt_axb = 2.0 * AXB(dt_3d1);
            u(:,:,1:kbm1) = u(:,:,1:kbm1)-tps_3d + (utb_3d+utf_3d) ./ dt_axb;
            
% 
%             tps =zeros(im,jm);
%             for k=1:kbm1
%                 tps=tps+v(:,:,k)*dz(k);
%             end
%?
            tps = sum(v(:,:,1:kbm1) .* dz_3d(:,:,1:kbm1), 3);
            
%             for k=1:kbm1
%                 v(:,:,k)=(v(:,:,k)-tps) + DIVISION((vtb+vtf), 2.0*AYB(dt));
%             end
           
            vtb_3d = repmat(vtb, 1, 1, kbm1);
            vtf_3d = repmat(vtf, 1, 1, kbm1);
            tps_3d = repmat(tps, 1, 1, kbm1);
            dt_ayb = 2.0 * AYB(dt_3d1);
            v(:,:,1:kbm1) = v(:,:,1:kbm1) - tps_3d + (vtb_3d+vtf_3d) ./ dt_ayb;
            

            %     vertvl calculates w from u, v, dt (h+et), etf and etb:
            %
            
            [a,c,w]=vertvl(a,c,w,dx,dy,dz,dt,u,v,vfluxb,vfluxf,etf,etb,dti2,im,jm,imm1,jmm1,kbm1);  
            %[a0,c0,w0]=new_vertvl(a,c,w,dx,dy,dz,dt,u,v,vfluxb,vfluxf,etf,etb,dti2,im,jm,imm1,jmm1,kbm1);  

            [elf,uaf,vaf,uf,vf,w] = new_bcond(5,elf,uaf,vaf,uf,vf,w,...
                im,jm,kb,imm1,jmm1,kbm1,...
                fsm,grav,ramp,rfe,h,uabe,ele,el,uabw,rfw,elw,rfn,eln,vabs,rfs,els,...
                dum,dvm,hmax,u,v,t,s,tbn,sbn,dti,tbs,sbs,q2,q2l,small,vabn,dx,dy,dt,tbe,sbe,tbw,sbw,zz);
            
            vf=zeros(im,jm,kb);
            uf=zeros(im,jm,kb);
                          
            % calculate q2f and q2lf using uf, vf, a and c as temporary variables:
           % [q2b,q2,uf,a,c]=advq(q2b,q2,uf,a,c,...
           %     dt,dx,dy,dz,u,v,w,aam,h,dum,dvm,art,etb,etf,im,jm,imm1,jmm1,kbm1,dti2);
           uf=new_advq(q2b,q2,dt,u,v,w,aam,h,etb,etf,dti2);    
           % [q2lb,q2l,vf,a,c]=advq(q2lb,q2l,vf,a,c,...
           %     dt,dx,dy,dz,u,v,w,aam,h,dum,dvm,art,etb,etf,im,jm,imm1,jmm1,kbm1,dti2);
           vf=new_advq(q2lb,q2l,dt,u,v,w,aam,h,etb,etf,dti2);  
          
            [a,c,tps,dtef,...
                ee,gg,l,kq,km,kh,...
                uf,vf,q2b,q2lb,a,c]=new_profq(a,c,tps,dtef,....
                ee,gg,l,kq,km,kh,...
                uf,vf,q2,q2b,q2lb,a,c,...
                h,etf,dti2,umol,dzz,grav,rho,kappa,u,v,dt,small,fsm,im,jm,kb,imm1,jmm1,kbm1,tbias,sbias,dz,...
                wusurf,wubot,wvsurf,wvbot,t,s,rhoref,zz,z);
            
            [elf,uaf,vaf,uf,vf,w] = new_bcond(6,elf,uaf,vaf,uf,vf,w,...
                im,jm,kb,imm1,jmm1,kbm1,...
                fsm,grav,ramp,rfe,h,uabe,ele,el,uabw,rfw,elw,rfn,eln,vabs,rfs,els,...
                dum,dvm,hmax,u,v,t,s,tbn,sbn,dti,tbs,sbs,q2,q2l,small,vabn,dx,dy,dt,tbe,sbe,tbw,sbw,zz);
            
            q2=q2+.5e0*smoth*(uf+q2b-2.e0*q2);
            q2l=q2l+.5e0*smoth*(vf+q2lb-2.e0*q2l);
            q2b=q2;
            q2=uf;
            q2lb=q2l;
            q2l=vf;
            
            %
            %      calculate tf and sf using uf, vf, a and c as temporary variables:
            %
            if(mode~=4)
                if(nadv==1)    
                    uf=new_advt1(tb,t,dt,u,v,aam,tprni,w,etb,etf,h);
                    vf=new_advt1(sb,s,dt,u,v,aam,tprni,w,etb,etf,h);
                elseif(nadv==2)                  
                    [tb,t,tclim,uf,a,c,nitera,sw,...
                     zflux] = advt2(tb,t,tclim,uf,a,c,nitera,sw,...
                                                 zflux,...
                                                 im,jm,kb,imm1,jmm1,kbm1,dti2,...
                                                 etb,etf,w,art,fsm,dt,aam,tprni,h,dum,dvm,dx,dy,u,v,aru,arv,dz,dzz);
                    [sb,s,sclim,vf,a,c,nitera,sw,...
                     zflux] = advt2(sb,s,sclim,vf,a,c,nitera,sw,...
                                                 zflux,...
                                                 im,jm,kb,imm1,jmm1,kbm1,dti2,...
                                                 etb,etf,w,art,fsm,dt,aam,tprni,h,dum,dvm,dx,dy,u,v,aru,arv,dz,dzz);      
                    %
                else
                    disp 'Invalid value for nadv ..... '
                    disp 'program terminated'
                    
                    return
                end

                [uf] = new_proft(uf,wtsurf,tsurf,nbct,h,etf,swrad,kh);
                [vf] = new_proft(vf,wssurf,ssurf,nbcs,h,etf,swrad,kh);
                
                [elf,uaf,vaf,uf,vf,w] = new_bcond(4,elf,uaf,vaf,uf,vf,w,...
                    im,jm,kb,imm1,jmm1,kbm1,...
                    fsm,grav,ramp,rfe,h,uabe,ele,el,uabw,rfw,elw,rfn,eln,vabs,rfs,els,...
                    dum,dvm,hmax,u,v,t,s,tbn,sbn,dti,tbs,sbs,q2,q2l,small,vabn,dx,dy,dt,tbe,sbe,tbw,sbw,zz);
                               
                t=t+.5e0*smoth*(uf+tb-2.e0*t);
                s=s+.5e0*smoth*(vf+sb-2.e0*s);
                tb=t;
                t=uf;
                sb=s;
                s=vf;

                [rho]=new_dens(s,t,h_3d,fsm_3d);
            end  % end if
            % calculate uf and vf:
            uf = new_advu(advx,cor,dt,e_atmos,drhox,h,ub,u,v,w,egf,egb,etf,etb);
            vf = new_advv(advy,cor,dt,e_atmos,drhoy,h,vb,u,v,w,egf,egb,etf,etb);
            
            vf0=vf;
            
            [uf,wubot] = new_profu(uf,etf,h,km,wusurf,cbc,ub,vb);           
            [vf,wvbot] = new_profv(vf,etf,h,km,wvsurf,cbc,ub,vb);
            
            [elf,uaf,vaf,uf,vf,w] = new_bcond(3,elf,uaf,vaf,uf,vf,w,...
                im,jm,kb,imm1,jmm1,kbm1,...
                fsm,grav,ramp,rfe,h,uabe,ele,el,uabw,rfw,elw,rfn,eln,vabs,rfs,els,...
                dum,dvm,hmax,u,v,t,s,tbn,sbn,dti,tbs,sbs,q2,q2l,small,vabn,dx,dy,dt,tbe,sbe,tbw,sbw,zz);
            
%             tps = zeros(im,jm);
% 
%             for k=1:kbm1
%                 for j=1:jm
%                     for i=1:im
%                         tps(i,j)=tps(i,j)     ...
%                             +(uf(i,j,k)+ub(i,j,k)-2.e0*u(i,j,k))*dz(k);
%                     end
%                 end
%             end
            tps = sum((uf+ub-2.e0*u).*dz_3d, 3);
            %
%             for k=1:kbm1
%                 for j=1:jm
%                     for i=1:im
%                         u(i,j,k)=u(i,j,k)     ...
%                             +.5e0*smoth*(uf(i,j,k)+ub(i,j,k)     ...
%                             -2.e0*u(i,j,k)-tps(i,j));
%                     end
%                 end
%             end
            tps_3d = repmat(tps, 1, 1, kbm1);
            u(:,:,1:kbm1)=u(:,:,1:kbm1)+ ...
                .5e0*smoth*(uf(:,:,1:kbm1)+ub(:,:,1:kbm1)-2.e0*u(:,:,1:kbm1)-tps_3d);
            %
%           tps = zeros(im,jm);
%             for k=1:kbm1
%                 for j=1:jm
%                     for i=1:im
%                         tps(i,j)=tps(i,j)     ...
%                             +(vf(i,j,k)+vb(i,j,k)-2.e0*v(i,j,k))*dz(k);
%                     end
%                 end
%             end
            tps = sum((vf+vb-2.e0*v).*dz_3d, 3);
            
            %
%             for k=1:kbm1
%                 for j=1:jm
%                     for i=1:im
%                         v(i,j,k)=v(i,j,k)     ...
%                             +.5e0*smoth*(vf(i,j,k)+vb(i,j,k)     ...
%                             -2.e0*v(i,j,k)-tps(i,j));
%                     end
%                 end
%             end
            %
            tps_3d = repmat(tps,1,1,kbm1);
            v(:,:,1:kbm1) = v(:,:,1:kbm1)+ ...
                .5e0*smoth*(vf(:,:,1:kbm1)+vb(:,:,1:kbm1)-2.e0*v(:,:,1:kbm1)-tps_3d);
            
            ub=u;
            u=uf;
            vb=v;
            v=vf;
            %
        end  % end if
        %        %
        egb=egf;
        etb=et;
        et=etf;
        dt=h+et;
        utb=utf;
        vtb=vtf;
        vfluxb=vfluxf;
        %
    end   % end if
    
  

    %
    %     Beginning of print section:
    %
    if(iint>=iswtch)
        iprint=floor(prtd2*24.e0*3600.e0/dti + 0.5);
    end
    %
    if(mod(iint,iprint)==0 || vamax>=vmaxl)
        fprintf('**************************************************\n');
        fprintf('**************************************************\n');
        fprintf('time = %.6f, iint = %d, iexit = %d, iprint = %d\n',time,iint,iext,iprint);
        
        %
        %     Select print statements in printall as desired:
        %
        %printall
        %
        vtot=0.e0;
        atot=0.e0;
        taver=0.e0;
        saver=0.e0;
        eaver=0.e0;
%         for k=1:kbm1
%             for j=1:jm
%                 for i=1:im
%                     darea=dx(i,j)*dy(i,j)*fsm(i,j);
%                     dvol=darea*dt(i,j)*dz(k);
%                     vtot=vtot+dvol;
%                     taver=taver+tb(i,j,k)*dvol;
%                     saver=saver+sb(i,j,k)*dvol;
%                 end
%             end
%         end
        
        dt_3d1 = repmat(dt, 1, 1, kb);
        tmp_dvol = dx_3d(:,:,1:kbm1).*dy_3d(:,:,1:kbm1).*fsm_3d(:,:,1:kbm1).*dt_3d1(:,:,1:kbm1).*dz_3d(:,:,1:kbm1);
        vtot=sum(tmp_dvol(:));
        taver=sum(reshape(tb(:,:,1:kbm1).*tmp_dvol,[],1));
        saver=sum(reshape(sb(:,:,1:kbm1).*tmp_dvol,[],1));

%         fprintf('diff_vtot:%.18f\n', vtot1-vtot);
%         fprintf('diff_taver:%.18f\n', taver1-taver);
%         fprintf('diff_saver:%.18f\n', saver1-saver);
        
        %
%         for j=1:jm
%             for i=1:im
%                 darea=dx(i,j)*dy(i,j)*fsm(i,j);
%                 atot=atot+darea;
%                 eaver=eaver+et(i,j)*darea;
%             end
%         end
        %
        darea = dx.*dy.*fsm;
        atot = sum(darea(:));
        eaver = sum(reshape(et.*darea,[],1));
        
        taver=taver/vtot;
        saver=saver/vtot;
        eaver=eaver/atot;
        tsalt=(saver+sbias)*vtot;
      
        fprintf('vtot = %.6f,atot = %.6f\n',vtot,atot);
        fprintf('eaver = %.6f,taver = %.6f,saver=%.6f,saver = %.6f,tsalt = %.6f\n',eaver,taver,saver,tsalt,tsalt);
        
        
        if(vamax>vmaxl)
            
            fprintf('time = %.6f, iint = %.6f, iexit = %.6f, iprint = %.6f\n',time,iint,iext,iprint);
           
            printall(im,jm,imm1,jmm1,iskp,jskp,uab,vab,elb,d,dx,dy,time,u,v,w,t,s,rho,aam,km,kb,mode,dt,zz,z);
           
            disp        '************************************************'
            disp        '************ abnormal job end ******************'
            disp        '************* user terminated ******************'
            disp        '************************************************'
            
            fprintf('vamax = %d, imax = %d ,jmax = %d \n',vmax,imax,jmax);
            return;
            %
        end
        %
    end
    %
    %     End of print section
    %-----------------------------------------------------------------------
    %
    %  End of internal (3-D) mode
    %-----------------------------------------------------------------------  
end
%internal loop ended
%write(6,4) time,iint,iext,iprint

fprintf('time = %d, iint = %d ,iext = %d , iprint = %d \n',time,iint,iext,iprint);
%
%     Set levels for output:
%
ko(1)=1;
ko(2)=2;
ko(3)=kb/2;
ko(4)=kb-1;
ko(5)=kb;
%
%      prxyz('Vertical velocity, w                    ',
%    ...           time,w       ,im,iskp,jm,jskp,kb,ko,5,-1.e0)
%
%      prxyz('Turbulent kinetic energy x 2, q2        ',
%    ...           time,q2      ,im,iskp,jm,jskp,kb,ko,5,-1.e0)
%
%     Save this data for a seamless restart:
%
%    write_to_file(im,jm,kb,time,wubot,wvbot,aam2d,ua,uab,va,vab,el,elb,et,etb,egb,...
%    utb,vtb,u,ub,w,v,vb,t,tb,s,sb,rho,adx2d,ady2d,advua,advva,...
%    km,kh,kq,l,q2,q2b,aam,q2l,q2lb);
    printall(im,jm,imm1,jmm1,iskp,jskp,uab,vab,elb,d,dx,dy,time,u,v,w,t,s,rho,aam,km,kb,mode,dt,zz,z);
    
%     End of main program