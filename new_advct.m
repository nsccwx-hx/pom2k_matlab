function [advx,advy]= new_advct(u,v,dx,dy,dt,aam,ub,vb,aru,arv)
% **********************************************************************
% *                                                                    *
% * FUNCTION    :  Calculates the horizontal portions of momentum      *
% *                advection well in advance of their use in advu and  *
% *                advv so that their vertical integrals (created in   *
% *                the main program) may be used in the external (2-D) *
% *                mode calculation.                                   *
% **********************************************************************
load('grid.mat');

curv=zeros(im,jm,kb);
advx=zeros(im,jm,kb);
advy=zeros(im,jm,kb);
xflux=zeros(im,jm,kb);
yflux=zeros(im,jm,kb);

for k=1:kb
    curv(:,:,k)= (AYF_XY(v(:,:,k)) .* DXB_XY(AXF_XY(dy)) - AXF_XY(u(:,:,k)) .* DYB_XY(AYF_XY(dx)) ) ./ (dx .* dy);
end
%
%     Calculate x-component of velocity advection:
%
for k=1:kb
    xflux(:,:,k) = dy .* (AXF_XY( AXB_XY(dt) .* u(:,:,k) ) .* AXF_XY(u(:,:,k)) ...
                    - dt.*aam(:,:,k)*2.0.*DXF_XY(ub(:,:,k))./dx );
    yflux(:,:,k) = AYB_XY(AXB_XY(dx)) .* (AXB_XY( AYB_XY(dt) .* v(:,:,k) ) .* AYB_XY(u(:,:,k)) ...
                    - AYB_XY(AXB_XY(dt)) .* AYB_XY(AXB_XY(aam(:,:,k))) ...
                     .* ( DYB_XY(ub(:,:,k)) ./ AYB_XY(AXB_XY(dy)) + DXB_XY(vb(:,:,k)) ./ AYB_XY(AXB_XY(dx))) ) ;                
    %set NaN caused by D/A operation to 0.
    yflux(isnan(yflux))=0;    
    %     for horizontal advection:   
    advx(:,:,k)=DXB_XY( xflux(:,:,k) ) + DYF_XY( yflux(:,:,k) ) ...
                    - aru .* AXB_XY(  curv(:,:,k) .* dt .* AYF_XY(v(:,:,k)) );    
end

xflux=zeros(im,jm,kb);
yflux=zeros(im,jm,kb);
%
%     Calculate y-component of velocity advection:
xflux1=xflux;
yflux1=yflux;
advy1=advy;
for k=1:kbm1
    for j=2:jm
        for i=2:im
            xflux(i,j,k)=.125e0*((dt(i,j)+dt(i-1,j))*u(i,j,k)     ...
                +(dt(i,j-1)+dt(i-1,j-1))*u(i,j-1,k))     ...
                *(v(i,j,k)+v(i-1,j,k));
        end
    end
end

for k=1:kbm1
    for j=2:jmm1
        for i=1:im
            yflux(i,j,k)=.125e0*((dt(i,j+1)+dt(i,j))*v(i,j+1,k)     ...
                +(dt(i,j)+dt(i,j-1))*v(i,j,k))     ...
                *(v(i,j+1,k)+v(i,j,k));
        end
    end
end

%
%    Add horizontal diffusive fluxes:
%
for k=1:kbm1
    for j=2:jmm1
        for i=2:im
            dtaam=.25e0*(dt(i,j)+dt(i-1,j)+dt(i,j-1)+dt(i-1,j-1))     ...
                *(aam(i,j,k)+aam(i-1,j,k)     ...
                +aam(i,j-1,k)+aam(i-1,j-1,k));
            xflux(i,j,k)=xflux(i,j,k)     ...
                -dtaam*((ub(i,j,k)-ub(i,j-1,k))     ...
                /(dy(i,j)+dy(i-1,j)     ...
                +dy(i,j-1)+dy(i-1,j-1))     ...
                +(vb(i,j,k)-vb(i-1,j,k))     ...
                /(dx(i,j)+dx(i-1,j)     ...
                +dx(i,j-1)+dx(i-1,j-1)));
            yflux(i,j,k)=yflux(i,j,k)     ...
                -dt(i,j)*aam(i,j,k)*2.e0     ...
                *(vb(i,j+1,k)-vb(i,j,k))/dy(i,j);
            %
            xflux(i,j,k)=.25e0*(dy(i,j)+dy(i-1,j)     ...
                +dy(i,j-1)+dy(i-1,j-1))*xflux(i,j,k);
            yflux(i,j,k)=dx(i,j)*yflux(i,j,k);
        end
    end
end



for k=1:kbm1
    for j=2:jmm1
        for i=2:imm1
            advy(i,j,k)=xflux(i+1,j,k)-xflux(i,j,k)     ...
                +yflux(i,j,k)-yflux(i,j-1,k);
        end
    end
end

for k=1:kb
            
    xflux1(:,:,k) =AYB_XY(AXB_XY(dy)) .* (AYB_XY( AXB_XY(dt) .* u(:,:,k) ) .* AXB_XY(v(:,:,k)) ...
                   - AYB_XY(AXB_XY(dt)) .* AYB_XY(AXB_XY(aam(:,:,k))) ...
                     .* ( DYB_XY(ub(:,:,k)) ./ AYB_XY(AXB_XY(dy)) + DXB_XY(vb(:,:,k)) ./ AYB_XY(AXB_XY(dx))) ) ;      
    yflux1(:,:,k) =dx .* (AYF_XY( AYB_XY(dt) .* v(:,:,k) ) .* AYF_XY(v(:,:,k)) ...
                    - dt.* aam(:,:,k)*2.0.*DYF_XY(vb(:,:,k)) ./dy ); 
    %set NaN caused by D/A operation to 0.
    xflux1(isnan(xflux1))=0;
    %for horizontal advection:
    advy1(:,:,k)=DXF_XY( xflux1(:,:,k) ) + DYB_XY( yflux1(:,:,k) ) ;
%                     + arv .* AYB_XY(  curv(:,:,k) .* dt .* AXF_XY(u(:,:,k)) ); 
end

for k=1:kbm1
    for j=3:jmm1
        for i=2:imm1
            advy(i,j,k)=advy(i,j,k)     ...
                +arv(i,j)*.25e0     ...
                *(curv(i,j,k)*dt(i,j)     ...
                *(u(i+1,j,k)+u(i,j,k))     ...
                +curv(i,j-1,k)*dt(i,j-1)     ...
                *(u(i+1,j-1,k)+u(i,j-1,k)));
        end
    end
end



