function [d] = DetermineDeadline( T0, Tf, T_amb, I, C, fP, h0, hf)
%UNTITLED4 Summary of this function goes here
%   Detailed explanation goes here
Tdown=zeros(24,1);
Tdown(hf)=Tf;
Tup=zeros(24,1);
Tup(h0)=T0;
for i=(hf-1):-1:h0
    Tdown(i)=(Tdown(i+1)+fP*I*C-T_amb(i+1)*I)/(1-I);
end
if Tdown(h0)<Tup(h0)
    for i=(h0-1):-1:1
        Tdown(i)=(Tdown(i+1)+fP*I*C-T_amb(i+1)*I)/(1-I);
        Tup(i)=(Tup(i+1)-T_amb(i+1)*I)/(1-I);
        if Tdown(i)>=Tup(i)
            d=i;
            return;
        end
    end
    d=0; 
    return;
else
    for i=(h0+1):hf
        Tup(i)=Tup(i-1)*(1-I)+T_amb(i-1)*I;
        if  Tdown(i)<=Tup(i)
            d=i-1;
            return;
        end            
    end
    d=25;
    return;
%     for i=(hf+1):24
%         Tdown(i)=Tdown(i-1)*(1-I)+T_amb(i-1)*I-fP*I*C;
%         Tup(i)=Tup(i-1)*(1-I)+T_amb(i-1)*I;
%         if  Tdown(i)>=Tup(i)
%             d=i-1;
%             return;
%         end            
%     end
end


end

