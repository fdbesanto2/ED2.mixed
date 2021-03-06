#==========================================================================================#
#==========================================================================================#
#     These are some global variables used by the thermodynamic library.                   #
#==========================================================================================#
#==========================================================================================#

#------------------------------------------------------------------------------------------#
#     These constants came from the paper in which the saturation vapour pressure is       #
# based on:                                                                                #
#                                                                                          #
#  Murphy, D. M.; Koop, T., 2005: Review of the vapour pressures of ice and supercooled    #
#     water for atmospheric applications. Q. J. Royal Meteor. Soc., vol. 31, pp. 1539-     #
#     1565 (hereafter MK05).                                                               #
#                                                                                          #
#  These equations give the triple point at t3ple, with vapour pressure being es3ple.      #
#------------------------------------------------------------------------------------------#
#----- Coefficients based on equation (7): ------------------------------------------------#
iii.7  <<- c(9.550426,-5723.265, 3.53068,-0.00728332)
#----- Coefficients based on equation (10), first fit -------------------------------------#
l01.10 <<- c(54.842763,-6763.22 ,-4.210  , 0.000367)
#----- Coefficients based on equation (10), second fit ------------------------------------#
l02.10 <<- c(53.878   ,-1331.22 ,-9.44523, 0.014025)
#----- Coefficients based on the hyperbolic tangent ---------------------------------------#
ttt.10 <<- c(0.0415,218.8)
#------------------------------------------------------------------------------------------#





#==========================================================================================#
#==========================================================================================#
#     This function calculates the saturation vapour pressure as a function of Kelvin      #
# temperature.                                                                             #
#------------------------------------------------------------------------------------------#
eslif <<- function(temp,funout=FALSE){

   liq = is.finite(temp) & temp >= t3ple
   ice = is.finite(temp) & temp <  t3ple

   l1fun = NA + temp
   l2fun = NA + temp
   ttfun = NA + temp
   iifun = NA + temp
   esfun = NA + temp

   if (any(liq)){
      l1fun[liq] = ( l01.10[1] + l01.10[2]/temp[liq] + l01.10[3]*log(temp[liq])
                   + l01.10[4] * temp[liq] )
      l2fun[liq] = ( l02.10[1] + l02.10[2]/temp[liq] + l02.10[3]*log(temp[liq])
                   + l02.10[4] * temp[liq] )
      ttfun[liq] = tanh(ttt.10[1] * (temp[liq] - ttt.10[2]))
      esfun[liq] = exp(l1fun[liq] + ttfun[liq] * l2fun[liq])
   }#end if

   if (any(ice)){
      iifun[ice] = ( iii.7[1] + iii.7[2]/temp[ice] + iii.7[3] * log(temp[ice])
                   + iii.7[4] * temp[ice] )
      esfun[ice]  = exp(iifun[ice])
   }#end if
   
   if (funout){
      ans = list(esfun = esfun,l1fun = l1fun, l2fun=l2fun, ttfun = ttfun, iifun = iifun)
      return(ans)
   }else{
      return(esfun)
   }#end if
}#end function eslif
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#     This function calculates the derivative of the saturation vapour pressure as a       #
# function of Kelvin temperature.                                                          #
#------------------------------------------------------------------------------------------#
eslifp <<- function(temp){

   liq = is.finite(temp) & temp >= t3ple
   ice = is.finite(temp) & temp <  t3ple

   #------ Find the saturation vapour pressure and the function evaluations. --------------#
   efun    = eslif(temp,funout = TRUE)
   l1fun   = efun$l1fun
   l2fun   = efun$l2fun
   ttfun   = efun$ttfun
   iifun   = efun$iifun
   esfun   = efun$esfun
   #---------------------------------------------------------------------------------------#


   #------ Initialise the derivatives. ----------------------------------------------------#
   l1prime = NA + temp
   l2prime = NA + temp
   ttprime = NA + temp
   iiprime = NA + temp
   desdt   = NA + temp
   #---------------------------------------------------------------------------------------#


   #------ Solve the derivative for the liquid phase. -------------------------------------#
   if (any(liq)){
      l1prime [liq] = - l01.10[2] / temp[liq]^2 + l01.10[3]/temp[liq] + l01.10[4]
      l2prime [liq] = - l02.10[2] / temp[liq]^2 + l02.10[3]/temp[liq] + l02.10[4]
      ttprime [liq] = ttt.10[1] * (1.0 - ttfun[liq]^2)
      desdt   [liq] = esfun[liq] * ( l1prime[liq] + l2prime[liq] * ttfun[liq] 
                                   + l2fun[liq] * ttprime[liq] )
   }#end if
   #---------------------------------------------------------------------------------------#


   #------ Solve the derivative for the ice phase. ----------------------------------------#
   if (any(ice)){
      iiprime[ice] = -iii.7[2]/temp[ice]^2 + iii.7[3]/temp[ice] + iii.7[4]
      desdt  [ice] = esfun[ice] * iiprime[ice]
   }#end if
   #---------------------------------------------------------------------------------------#


   return(desdt)
}#end function eslifp
#==========================================================================================#
#==========================================================================================#





#==========================================================================================#
#==========================================================================================#
#     This function calculates the saturation vapour mixing ratio as a function of         #
# pressure and Kelvin temperature.                                                         #
#------------------------------------------------------------------------------------------#
rslif <<- function (pres,temp){

   esl                   = eslif(temp)
   rsfun                 = ep * esl / (pres - ep * esl)
   zero                  = is.finite(rsfun) & rsfun < toodry
   rsfun[rsfun < toodry] = toodry

   return(rsfun)
}# end function rslif
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#     This function calculates the derivative of the saturation mixing ratio as a          #
# function of Kelvin temperature.                                                          #
#------------------------------------------------------------------------------------------#
rslifp <<- function(pres,temp){

   #----- Find the saturation vapour pressure and its derivative at temperature temp. -----#
   esli  = eslif (temp)
   desdt = eslifp(temp)
   #---------------------------------------------------------------------------------------#


   #----- Find the partial pressure of dry air. -------------------------------------------#
   pdry  = pres - esli
   #---------------------------------------------------------------------------------------#


   #----- Find the partial derivative of mixing ratio. ------------------------------------#
   drsdt = ep * pres * desdt / (pdry*pdry)
   #---------------------------------------------------------------------------------------#

   return(drsdt)
}#end function rslifp
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#     This function calculates the saturation vapour specific humidity as a function of    #
# pressure and Kelvin temperature.                                                             #
#------------------------------------------------------------------------------------------#
qslif <<- function (pres,temp){

   esl                   = eslif(temp)
   qsfun                 = ep * esl / (pres - (1.-ep) * esl)
   zero                  = is.finite(qsfun) & qsfun < toodry
   qsfun[qsfun < toodry] = toodry

   return(qsfun)
}# end function rslif
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#     This function calculates the saturation vapour specific humidity as a function of    #
# pressure and Kelvin temperature.                                                         #
#------------------------------------------------------------------------------------------#
tslif <<- function (pres,hum,type.hum="shum"){

   #----- Find the partial pressure of water vapour. --------------------------------------#
   if (type.hum == "shum"){
      pvap = pres * hum / ( ep + (1. - ep) * hum)
   }else if (type.hum == "rvap"){
      pvap = pres * hum / ( ep + hum )
   }else if (type.hum == "pvap"){
      pvap = hum
   }else{
      stop(paste(" Humidity type (",type.hum,") is not valid!",sep=""))
   }#end if
   #---------------------------------------------------------------------------------------#



   #---------------------------------------------------------------------------------------#
   #     Function that finds the root for any element.                                     #
   #---------------------------------------------------------------------------------------#
   find.tslif = function(pvap){
      dewpoint = function(temp,pvap) eslif(temp) - pvap

      if (is.na(pvap)){
         tdew = NA
      }else{
         t1st     = (1.814625 * log(pvap) +6190.134)/(29.120 - log(pvap))
         tdew     = uniroot(f=dewpoint,interval=c(t1st-30,t1st+30),pvap=pvap)$root
      }#end if
      return(tdew)
   }#end find.tslif
   #---------------------------------------------------------------------------------------#

   tdew = sapply(X=pvap,FUN=find.tslif,simplify=TRUE)

   return(tdew)
}# end function rslif
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#     This function calculates the relative humidity as a function of pressure, Kelvin     #
# temperature, and specific humidity.                                                      #
#------------------------------------------------------------------------------------------#
rehuil <<- function (pres,temp,shv){

   esat = eslif(temp)
   eair = pres * shv / (ep + (1. - ep) * shv)
   rhv  = eair / esat

   return(rhv)
}#end function rslif
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#     This function computes the vapour mixing ratio based on the pressure [Pa], tem-      #
# perature [K] and relative humidity [fraction]. It will check the temperature to          #
# decide between ice or liquid saturation and whether ice should be considered.            #
#------------------------------------------------------------------------------------------#
ptrh2shv <<- function(relh,pres,temp){

   #----- Find the saturation mixing ratio. -----------------------------------------------#
   qsath                 = qslif(pres,temp)
   qsath[qsath < toodry] = toodry
   #---------------------------------------------------------------------------------------#


   #----- Ensure that relative humidity is bounded. ---------------------------------------#
   relh   = pmax(0.,pmin(1.,relh))
   #---------------------------------------------------------------------------------------#


   #----- Find the mixing ratio. ----------------------------------------------------------#
   shvfun = pmax(toodry, ep * relh * qsath / (ep + (1.-relh)*(1.-ep)*qsath))
   #---------------------------------------------------------------------------------------#

   return(shvfun)
}# end function ptrh2shv
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#     This function finds the potential temperature given the temperature in Kelvin and    #
# pressure in Pascals.                                                                     #
#------------------------------------------------------------------------------------------#
potenttemp <<- function(temp,pres,shv){

   cpair = cpdry * (1. - shv) + shv * cph2o
   rair  = rdry  * (1. + epim1 * shv)

   thfun = temp * (p00 / pres)^(rair/cpair)
   return(thfun)
}#end function potenttemp
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#     This function finds the reduced mean sea level pressure given potential temperature, #
# pressure, and specific humidity (as vectors), and altitude.                              #
#------------------------------------------------------------------------------------------#
ptq2mslp <<- function(pres,theta,shv,zalt){

   #----- Find the mean specific heat and gas constant. -----------------------------------#
   cpair = cpdry * (1. - shv) + shv * cph2o
   rair  = rdry * (1. + epim1 * shv)
   rocpair = rair/cpair
   cporair = 1./ rocpair

   #----- Find the auxiliary term that will control the slope of the pressure. ------------#
   pinc  = p00^rocpair * grav * zalt / (cpair * theta)

   #----- Estimate the sea level pressure. ------------------------------------------------#
   mslp = ( pres ^ rocpair + pinc) ^ cporair

   return(mslp)
}#end function
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#     This function finds the surface level pressure given potential temperature, mean sea #
# level pressure, and specific humidity (as vectors), and altitude.                        #
#------------------------------------------------------------------------------------------#
potq2pres <<- function(pres,theta,shv,alt){

   #----- Find the mean specific heat and gas constant. -----------------------------------#
   cpair = cpdry * (1. - shv) + shv * cph2o
   rair  = rdry * (1. + epim1 * shv)
   rocpair = rair/cpair
   cporair = 1./ rocpair

   #----- Find the auxiliary term that will control the slope of the pressure. ------------#
   pinc  = p00^rocpair * grav * zalt / (cpair * theta)

   #----- Estimate the sea level pressure. -----------------------------------------------#
   pres = ( mslp ^ rocpair - pinc) ^ cporair

   return(pres)
}#end function
#==========================================================================================#
#==========================================================================================#





#==========================================================================================#
#==========================================================================================#
#     This function finds the latent heat of vaporisation for a given temperature.  If we  #
# use the definition of latent heat (difference in enthalpy between liquid and vapour      #
# phases), and assume that the specific heats are constants, latent heat becomes a linear  #
# function of temperature.                                                                 #
#------------------------------------------------------------------------------------------#
alvl <<- function(temp){

   #----- Linear function, using latent heat at the triple point as reference. ------------#
   lvap = alvl3 + dcpvl * (temp - t3ple)
   #---------------------------------------------------------------------------------------#

   return(lvap)
}#end function alvl
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#     This function finds the latent heat of sublimation for a given temperature.  If we   #
# use the definition of latent heat (difference in enthalpy between ice and vapour         #
# phases), and assume that the specific heats are constants, latent heat becomes a linear  #
# function of temperature.                                                                 #
#------------------------------------------------------------------------------------------#
alvi <<- function(temp){

   #----- Linear function, using latent heat at the triple point as reference. ------------#
   lsub = alvi3 + dcpvi * (temp - t3ple)
   #---------------------------------------------------------------------------------------#

   return(lsub)
}# end function alvi
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#     This function finds the latent heat towards vapour for a given temperature.  If we   #
# use the definition of latent heat (difference in enthalpy between ice and vapour         #
# phases), and assume that the specific heats are constants, latent heat becomes a linear  #
# function of temperature.                                                                 #
#------------------------------------------------------------------------------------------#
alvli <<- function(temp){

   #----- Find the sought phase. ----------------------------------------------------------#
   liq  = temp >  t3ple
   mix  = temp == t3ple
   ice  = temp <  t3ple
   #---------------------------------------------------------------------------------------#


   #----- Convert all flags that are NA to FALSE. -----------------------------------------#
   liq[is.na(liq)] = FALSE
   mix[is.na(mix)] = FALSE
   ice[is.na(ice)] = FALSE
   #---------------------------------------------------------------------------------------#


   #----- Initialise output with NA. ------------------------------------------------------#
   lvap = NA + temp
   #---------------------------------------------------------------------------------------#


   #----- Linear function, using latent heat at the triple point as reference. ------------#
   lvap[liq] = alvl3 + dcpvl * (temp[liq] - t3ple)
   lvap[mix] = 0.5 * (alvi3 + alvl3)
   lvap[ice] = alvi3 + dcpvi * (temp[ice] - t3ple)
   #---------------------------------------------------------------------------------------#

   return(lvap)
}# end function alvli
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#     This function finds the density based on the virtual temperature and the ideal  gas  #
# law.  The only difference between this function and the one above is that here we        # 
# provide vapour and total specific mass (specific humidity) instead of mixing ratio.      #
#------------------------------------------------------------------------------------------#
idealdenssh <<- function(pres,temp,qvpr,qtot=NULL){

   #---------------------------------------------------------------------------------------#
   #      Prefer using total specific humidity, but if it isn't provided, then use vapour  #
   # phase as the total (no condensation).                                                 #
   #---------------------------------------------------------------------------------------#
   if (is.null(qtot)) qtot = qvpr
   #---------------------------------------------------------------------------------------#


   #----- Convert using a generalised function. -------------------------------------------#
   rhos = pres / (rdry * temp * (1. - qtot + epi * qvpr))
   #---------------------------------------------------------------------------------------#
   
   return(rhos)
}#end if
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#    This subroutine finds the lifting condensation level given the ice-liquid             #
# potential temperature in Kelvin, temperature in Kelvin, the pressure in Pascal, and      #
# the mixing ratio in kg/kg. The output will give the LCL temperature and pressure, and    #
# the thickness of the layer between the initial point and the LCL.                        #
#                                                                                          #
#    References:                                                                           #
#    Tripoli, J. T.; and Cotton, W.R., 1981: The use of ice-liquid water potential         #
#        temperature as a thermodynamic variable in deep atmospheric models. Mon. Wea.     #
#        Rev., v. 109, 1094-1102. (TC81)                                                   #
#    Bolton, D., 1980: The computation of the equivalent potential temperature. Mon.       #
#        Wea. Rev., v. 108, 1046-1053. (BO80)                                              #
#                                                                                          #
#    Some algebra was needed to find this equation, essentially combining (TC81-26) and    #
# (TC81-27), and the conservation of total water (TC81-16). It assumes that the divi-      #
# sion between the three phases is already taken care of.                                  #
#    Iterative procedure is needed, and here we iterate looking for T(LCL). Theta_il       #
# can be rewritten in terms of T(LCL) only, and once we know this thetae_iv becomes        #
# straightforward.                                                                         #
#                                                                                          #
# Important remarks:                                                                       #
# 1. TLCL and PLCL are the actual TLCL and PLCL, so in case condensation exists, they      #
#    will be larger than the actual temperature and pressure (because one would go down    #
#    to reach the equilibrium);                                                            #
# 2. DZLCL WILL BE SET TO ZERO in case the LCL is beneath the starting level. So in        #
#    case you want to force TLCL <= TEMP and PLCL <= PRES, you can use this variable       #
#    to run the saturation check afterwards. DON'T CHANGE PLCL and TLCL here, they will    #
#    be used for conversions between theta_il and thetae_iv as they are defined here.      #
#------------------------------------------------------------------------------------------#
lcl.il <<- function(thil,pres,temp,hum,hum.tot=hum,type.hum="shum"){

   #---------------------------------------------------------------------------------------# 
   #    Find vapour pressure and vapour pressure at 1000. hPa, depending on the humidity   #
   # given.                                                                                #
   #---------------------------------------------------------------------------------------#
   if (type.hum == "pvap"){
      pvap = hum
      es00 = p00 * hum.tot / pres
   }else if (type.hum == "rvap"){
      pvap = pres * hum    / (ep + hum    )
      es00 = p00 * hum.tot / (ep + hum.tot)
   }else if (type.hum == "shum"){
      pvap = pres * hum     / (ep + (1. - ep) * hum    )
      es00 = p00  * hum.tot / (ep + (1. - ep) * hum.tot)
   }#end if
   #---------------------------------------------------------------------------------------#


   #---------------------------------------------------------------------------------------#
   #     Function that finds the root for any element.                                     #
   #---------------------------------------------------------------------------------------#
   find.tlcl = function(es00,pvap,temp,thil){
      lcl.root = function(tlcl,es00,thil) tlcl * (es00/eslif(tlcl))^rocp - thil

      undef = is.na(es00) | is.na(pvap) | is.na(thil)
      if (undef){
         ans  = NA
      }else{
         #---------------------------------------------------------------------------------#
         #     The 1st. guess, use equation 21 from Bolton (1980).                         #
         #---------------------------------------------------------------------------------#
         t1st = 55. + 2840. / (3.5 * log(temp) - log(0.01*pvap) - 4.805)
         sol  = uniroot(f=lcl.root,interval=c(t1st-30,t1st+30),es00=es00,thil=thil)
         ans  = sol$root
      }#end if
      return(ans)
   }#end find.tslif
   #---------------------------------------------------------------------------------------#

   tlcl  = mapply(FUN=find.tlcl,es00=es00,pvap=pvap,temp=temp,thil=thil,SIMPLIFY=TRUE)
   elcl  = eslif(tlcl)
   plcl  = p00 * elcl / es00
   dzlcl = pmax(0*elcl,cpog * (temp - tlcl))
   
   ans   = list(temp = tlcl, pvap = elcl, pres = plcl, height = dzlcl)
   
   return(ans)
}#end function lcl.il
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#    This function computes the saturation ice-vapour equivalent potential temperature     #
# from theta_il and the total mixing ratio (split into saturated vapour plus liquid and    #
# ice. This is equivalent to the equivalent potential temperature considering also the     #
# effects of fusion/melting/sublimation, and it is done separatedly from the regular       #
# thetae_iv because it doesn't require iterations.                                         #
#                                                                                          #
#    References:                                                                           #
#    Tripoli, J. T.; and Cotton, W.R., 1981: The use of ice-liquid water potential tem-    #
#        perature as a thermodynamic variable in deep atmospheric models. Mon. Wea.        #
#        Rev., v. 109, 1094-1102. (TC81)                                                   #
#                                                                                          #
#    Some algebra was needed to find this equation, essentially combining (TC81-26) and    #
# (TC81-27), and the conservation of total water (TC81-16). It assumes that the divi-      #
# sion between the three phases is already taken care of.                                  #
#------------------------------------------------------------------------------------------#
thetaeivs <<- function(thil,temp,rsat,rliq,rice){


   #------ Find the total saturation mixing ratio. ----------------------------------------#
   rtots  = rsat+rliq+rice
   #---------------------------------------------------------------------------------------#


   #------ Find the saturation equivalent potential temperature. --------------------------#
   theivs = thil * exp ( alvl(temp) * rtots / (cpdry * temp))
   #---------------------------------------------------------------------------------------#

   return(theivs)
}#end function thetaeivs
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#     This function computes the ice-vapour equivalent potential temperature from          #
# theta_iland the total mixing ratio.  This is equivalent to the equivalent potential      #
# temperature considering also the effects of fusion/melting/sublimation.                  #
#     In case you want to find thetae (i.e. without ice) simply set the the logical        #
# useice to .false. .                                                                      #
#------------------------------------------------------------------------------------------#
thetaeiv <<- function(thil,pres,temp,hum,hum.tot=hum,type.hum="shum"){

   #---------------------------------------------------------------------------------------#
   #     Convert humidity to mixing ratio.                                                 #
   #---------------------------------------------------------------------------------------#
   if (type.hum == "rvap"){
      rtot = hum.tot
      rvap = hum
   }else if(type.hum == "pvap"){
      rtot = ep * hum.tot / (pres - hum.tot)
      rvap = ep * hum     / (pres - hum    )
   }else if(type.hum == "shum"){
      rtot = hum.tot / (1. - hum.tot)
      rvap = hum     / (1. - hum.tot)
   }#end if
   #---------------------------------------------------------------------------------------#


   #----- Use the LCL definition, then find the saturation value at the LCL. --------------#
   tlcl  = lcl.il(thil,pres,temp,hum,hum.tot=hum,type.hum)$temp
   theiv = thetaeivs(thil,tlcl,rtot,0.,0.)
   #---------------------------------------------------------------------------------------#

   return(theiv)
}#end function thetaeiv
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#      Function that estimates the precipitable water, using the same equation as:         #
#                                                                                          #
# Marthews, T. R., Y. Malhi, H. Iwata, 2012: Calculating downward longwave radiation under #
#     clear and cloudy conditions over a tropical lowland forest site: an evaluation of    #
#     model schemes for hourly data.  Theor. Appl. Climatol., 107, 461-477.                #
#------------------------------------------------------------------------------------------#
prec.water <<- function(pvap,atm.tmp) 4.65 * pvap / atm.tmp
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#      Function that estimates evapotranspiration, if the aerodynamic and stomatal         #
# conductances are known.                                                                  #
#------------------------------------------------------------------------------------------#
tpn2pet <<- function(atm.tmp,atm.prss,atm.shv,rnet,ga,gs){
   desdt    = eslifp(atm.tmp)
   latent   = alvli (atm.tmp)
   atm.pvap = atm.prss * atm.shv / ( ep + (1. - ep) * atm.shv)
   atm.vpd  = pmax(0,eslif(atm.tmp)-atm.pvap)
   atm.rhos = idealdenssh(atm.prss,atm.tmp,atm.shv)
   pet      = ( day.sec * ( desdt * rnet  + atm.rhos * cpdry * atm.vpd  * ga )
                        / ( desdt * latent + epi * cpdry * atm.prss * (1. + ga/gs)) )
   return(pet)
}#end function
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#      Function that estimates the conductances for potential evapotranspiration.          #
#------------------------------------------------------------------------------------------#
tpn2pet.fit <<- function(atm.tmp,atm.prss,atm.shv,rnet,wflxca){
   desdt    = eslifp(atm.tmp)
   latent   = alvli (atm.tmp)
   atm.pvap = atm.prss * atm.shv / ( ep + (1. - ep) * atm.shv)
   atm.vpd  = pmax(0,eslif(atm.tmp)-atm.pvap)
   atm.rhos = idealdenssh(atm.prss,atm.tmp,atm.shv)

   lsq = function(x,atm.tmp,atm.prss,atm.shv,rnet,wflxca){
      ga    = exp(x[1])
      gs    = exp(x[2])
      test  = tpn2pet(atm.tmp,atm.prss,atm.shv,rnet,ga,gs)
      sumsq = sum((wflxca-test)^2,na.rm=TRUE)
      return(sumsq)
   }#end lsq

   x1     = log(c(0.033,0.003))
   fit    = optim( par      = x1
                 , fn       = lsq
                 , atm.tmp  = atm.tmp 
                 , atm.prss = atm.prss
                 , atm.shv  = atm.shv 
                 , rnet     = rnet    
                 , wflxca   = wflxca  
                 )#end optim
   if (fit$convergence == 0){
      ga     = exp(fit$par[1])
      gs     = exp(fit$par[2])
   }else{
      ga     = NA
      gs     = NA
   }#end if
   ans = list(ga=ga,gs=gs)
   return(ans)
}#end function
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#    This subroutine computes the temperature and fraction of liquid water from the        #
# intensive internal energy [J/kg].                                                        #
#------------------------------------------------------------------------------------------#
uint2tl <<- function(uint){


   #----- Initialise the output with NA. --------------------------------------------------#
   temp   = rep(NA,times=length(uint))
   fliq   = rep(NA,times=length(uint))
   #---------------------------------------------------------------------------------------#


   #---------------------------------------------------------------------------------------#
   #     Compare the internal energy with the reference values to decide which phase the   #
   # water is.                                                                             #
   #---------------------------------------------------------------------------------------#
   fine = is.finite(uint)
   ice  = fine & uint <= uiicet3
   liq  = fine & uint >= uiliqt3
   melt = fine & uint >  uiicet3 & uint <  uiliqt3
   #---------------------------------------------------------------------------------------#



   #----- Internal energy below qwfroz, all ice  ------------------------------------------#
   fliq[ice]  = 0.
   temp[ice]  = uint[ice] * cicei
   #---------------------------------------------------------------------------------------#


   #----- Internal energy, above qwmelt, all liquid ---------------------------------------#
   fliq[liq]  = 1.
   temp[liq]  = uint[liq] * cliqi + tsupercool.liq
   #---------------------------------------------------------------------------------------#


   #----- Changing phase, it must be at freezing point ------------------------------------#
   fliq[melt] = (uint[melt] - uiicet3) * allii
   temp[melt] = t3ple
   #---------------------------------------------------------------------------------------#


   ans = list(temp=temp,fliq=fliq)
   return(ans)
}#end function uint2tl
#==========================================================================================#
#==========================================================================================#






#==========================================================================================#
#==========================================================================================#
#    This subroutine computes the temperature (Kelvin) and liquid fraction from            #
# extensive internal energy (J/m2 or J/m3), water mass (kg/m2 or kg/m3), and heat          #
# capacity (J/m2/K or J/m3/K).                                                             #
#------------------------------------------------------------------------------------------#
uextcm2tl <<- function(uext,wmass,dryhcap){



   #----- Convert melting heat to J/m2 or J/m3 --------------------------------------------#
   uefroz = (dryhcap + wmass * cice) * t3ple
   uemelt = uefroz   + wmass * alli
   #---------------------------------------------------------------------------------------#


   #----- Initialise the output with NA. --------------------------------------------------#
   temp   = rep(NA,times=length(uext))
   fliq   = rep(NA,times=length(uext))
   #---------------------------------------------------------------------------------------#


   #---------------------------------------------------------------------------------------#
   #    This is analogous to the uint2tl computation, we should analyse the magnitude of   #
   # the internal energy to choose between liquid, ice, or both by comparing with the      #
   # known boundaries.                                                                     #
   #---------------------------------------------------------------------------------------#
   fine = is.finite(uext) & is.finite(wmass) & is.finite(dryhcap)
   ice  = fine & uext < uefroz
   liq  = fine & uext > uemelt
   rien = fine & uefroz == uemelt
   melt = fine & uext >= uefroz & uext <= uemelt
   #---------------------------------------------------------------------------------------#



   #----- Internal energy below qwfroz, all ice  ------------------------------------------#
   fliq[ice] = 0.
   temp[ice] = uext[ice]  / (cice * wmass[ice] + dryhcap[ice])
   #---------------------------------------------------------------------------------------#


   #----- Internal energy, above qwmelt, all liquid ---------------------------------------#
   fliq[liq] = 1.
   temp[liq] = ( ( uext   [liq] + wmass[liq] * cliq * tsupercool.liq )
               / ( dryhcap[liq] + wmass[liq] * cliq ) )
   #---------------------------------------------------------------------------------------#


   #---------------------------------------------------------------------------------------#
   #     We are at the freezing point.  If water mass is so tiny that the internal energy  #
   # of frozen and melted states are the same given the machine precision, then we assume  #
   # that water content is negligible and we impose 50% frozen for simplicity.             #
   #---------------------------------------------------------------------------------------#
   fliq[rien] = 0.5
   temp[rien] = t3ple
   #---------------------------------------------------------------------------------------#



   #---------------------------------------------------------------------------------------#
   #     Changing phase, it must be at freezing point.  The max and min are here just to   #
   # avoid tiny deviations beyond 0. and 1. due to floating point arithmetics.             #
   #---------------------------------------------------------------------------------------#
   fliq[melt] = (uext[melt] - uefroz[melt]) * allii / wmass[melt]
   temp[melt] = t3ple
   #---------------------------------------------------------------------------------------#


   #----- Make sure that liquid fraction is bounded. --------------------------------------#
   fliq = pmax(0,pmin(1,fliq))
   #---------------------------------------------------------------------------------------#

   ans = list(temp=temp,fliq=fliq)
   return(ans)
}#end function uextcm2tl
#==========================================================================================#
#==========================================================================================#
