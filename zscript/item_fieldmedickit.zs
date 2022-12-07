//-------------------------------------------------
// Proper bandages for proper first aid
//-------------------------------------------------

enum GauzeNums{
    GAUZE_GIVEWRAP = 1,//uses this much per bandage attempt
    GAUZE_MAXWRAP = 20,//20 uses from each me
    
    MEDS_GAUZE = 1,
}

class HDFieldMedicKit:HDWoundFixer{
	default{
	    -hdweapon.dontdisarm    		
	    -weapon.no_auto_switch
		+inventory.invbar
		-nointeraction
		+inventory.ishealth
		
		scale 0.5;
		weapon.selectionorder 1004;
		//weapon.slotnumber 9;
		//weapon.slotprioritiy 0.1
		tag "field medic kit";
		hdweapon.refid "fmd";
	}
	
	override bool AddSpareWeapon(actor newowner){return AddSpareWeaponRegular(newowner);}
	override hdweapon GetSpareWeapon(actor newowner,bool reverse,bool doselect){return GetSpareWeaponRegular(newowner,reverse,doselect);}
	
	override void initializewepstats(bool idfa){
		weaponstatus[MEDS_GAUZE]=GAUZE_MAXWRAP;
	}
	
	override string pickupmessage(){
		if(!weaponstatus[MEDS_GAUZE]>0)return "Picked up an empty field medic kit.";
		if(weaponstatus[MEDS_GAUZE]<GAUZE_MAXWRAP)return "Picked up a used field medic kit.";
		
		return "Picked up a field medic kit.";
	}

	override double weaponbulk(){
		return 10+weaponstatus[MEDS_GAUZE];//bulk is affected by amount of bandages left
	}
	
	void bandagewound(double amt,actor itg){
		if(itg){
			let tgw=targetwound;
			if(
				!tgw
				||tgw.bleeder!=itg
			){
				tgw=hdbleedingwound.findbiggest(itg);
				targetwound=tgw;
			}else if(
				!tgw.depth
			){
				targetwound=null;
				return;
			}
			if(tgw)tgw.patch(amt,false);
			else{
				wepmsg="There is no wound to treat.";
				msgtimer=70;
				if(owner.player)owner.player.setpsprite(PSP_WEAPON,findstate("nope"));
			}
		}
	}
	
	override string,double getpickupsprite(){
		return (weaponstatus[MEDS_GAUZE]<1)?"FMKTB0":"FMKTA0",1;
	}
	
	override string gethelptext(){return WEPHELP_INJECTOR
		.."\n"..WEPHELP_ALTRELOAD.."  Remove blood feeder"
		..(owner.countinv("BloodBagWorn")?"":"(if any)");}
		
	override void DrawHUDStuff(HDStatusBar sb,HDWeapon hdw,HDPlayerPawn hpl){
		let ww=HDFieldMedicKit(hdw);
		int of=0;

		let bwnd=targetwound;
		if(!bwnd||!bwnd.depth)bwnd=hdbleedingwound.findbiggest(hpl);
		if(
			bwnd
			&&bwnd.depth
		){
			sb.drawimage(
				"BLUDC0",(-19,-8),
				sb.DI_SCREEN_CENTER_BOTTOM|sb.DI_ITEM_RIGHT,
				0.1+(bwnd.depth)*0.07,scale:(0.1,0.1)*bwnd.width
			);
			of=clamp(int(bwnd.depth*0.2),1,3);
			if(hpl.flip)of=-of;
		}
		
		sb.drawrect(-22,-19+of,2,8);
		sb.drawrect(-25,-16+of,8,2);
		
		sb.drawrect(-34,-20+of,2,10);
		sb.drawrect(-39,-16+of,12,2);
		
		sb.drawwepnum(ww.weaponstatus[MEDS_GAUZE],GAUZE_MAXWRAP);

	}
	
	/*
	override inventory CreateTossable(int amt){
		//DropMeds(owner,0);
		//make this drop a real item
		return null;
	}
	*/
	
	
	int targetlock;
	states{
	select:
		TNT1 A 0{
			if(!DoHelpText()) return;
			if(!!hdbleedingwound.findbiggest(self,0))A_WeaponMessage("\cu--- \ccBANDAGING \cu---\c-\n\n\nPress and hold Fire\n\nwhile standing still\n\nto try to not die.",210);
			else A_WeaponMessage("\cu--- \ccFIELD MEDIC KIT \cu---\c-\n\n\nPress and hold Fire to bandage\n\nyourself when you are bleeding.\n\n\n\nPress and hold Altfire\n\nto bandage someone else.",210);
		}
		goto super::select;
	abort:
		TNT1 A 1{
			if(DoHelpText())A_WeaponMessage("You must stay still\n\nto bandage yourself!",70);
		}
		TNT1 A 0 A_Refire("lower");
		goto nope;
	nogauze:
		TNT1 A 1{
			if(DoHelpText())A_WeaponMessage("You are out of gauze.",70);
		}
		TNT1 A 0 A_Refire("lower");
		goto nope;
	fire:
		TNT1 A 0{
			invoker.targetwound=null;
			bool nope=false;
			let blockinv=HDWoundFixer.CheckCovered(self,CHECKCOV_ONLYFULL);
			if(blockinv){
				A_TakeOffFirst(blockinv.gettag());
				nope=true;
			}
			else if(!hdbleedingwound.findbiggest(self,0)){
				if(DoHelpText())A_WeaponMessage("You are not bleeding.",70);
				nope=true;
			}
			if(nope)player.setpsprite(PSP_WEAPON,invoker.findstate("nope"));
		}
	hold:
	lower:
		TNT1 A 0 A_JumpIf(pitch>45,"try");
		TNT1 A 1 A_MuzzleClimb(0,6);
		TNT1 A 0 A_JumpIf(invoker.weaponstatus[MEDS_GAUZE]<1,"nogauze");
		TNT1 A 0 A_JumpIf(IsMoving.Count(self)>=4,"abort");
		TNT1 A 0 A_Refire("lower");
		goto ready;
	try:
		TNT1 A random(15,25);
		TNT1 A 0{
			A_MuzzleClimb(frandom(-1.5,1.8),frandom(-2.4,2.4));
			if(hdplayerpawn(self))hdplayerpawn(self).fatigue+=2;
		}
		TNT1 A 0 A_Jump(32,2);
		TNT1 A random(5,15) damagemobj(self,self,1,"bleedout");
		TNT1 A 0 A_JumpIf(IsMoving.Count(self)>=4,"abort");
	try2:
		TNT1 A 0{
			A_MuzzleClimb(frandom(-1.5,1.8),frandom(-2.4,2.4));
			if(hdplayerpawn(self))hdplayerpawn(self).fatigue+=2;
		}
		TNT1 A random(1,3) A_Jump(32,2,4);
		TNT1 A 0 A_Jump(256,2);
		TNT1 A random(1,3) A_PlaySkinSound(SKINSOUND_GRUNT,"*usefail");
		TNT1 A 0 A_Jump(256,2);
		TNT1 A random(1,3) A_PlaySkinSound(SKINSOUND_GRUNT,"*grunt");
		TNT1 A 0 A_Jump(200,2);
		TNT1 A 0 A_StartSound("bandage/rip",CHAN_WEAPON,CHANF_OVERLAP,0.4);
		TNT1 A 0 A_Refire("try4");
		goto ready;
		
		/*
	try3:
		TNT1 A random(20,40){
			A_MuzzleClimb(frandom(-1.6,1.8),frandom(-2.4,2.4));
			if(hdplayerpawn(self))hdplayerpawn(self).fatigue+=2;
		}
		TNT1 A 0 A_Jump(200,2);
		TNT1 A 0 A_StartSound("bandage/rustle",CHAN_BODY,CHANF_OVERLAP);
		TNT1 A random(10,20);
		TNT1 A 0 A_JumpIf(IsMoving.Count(self)>=4,"abort");
		TNT1 A 0 A_Refire("try4");
		goto ready;
		*/
		//less tries means faster bandaging
		
	try3:
		TNT1 A 0 A_CheckFloor(2);
		TNT1 A 0 A_Jump(240,2);
		TNT1 A 0 A_ChangeVelocity(frandom(-0.3,0.3),frandom(-0.3,0.3),frandom(-1,2));
		TNT1 A 0{
			A_MuzzleClimb(frandom(-1.5,1.7),frandom(-2.4,2.4));
			if(hdplayerpawn(self))hdplayerpawn(self).fatigue+=2;
		}
		TNT1 A 0 A_Jump(240,2);
		TNT1 A random(1,3) A_PlaySkinSound(SKINSOUND_GRUNT,"*grunt");
		TNT1 A 0 A_Jump(140,2);
		TNT1 A 0 A_StartSound("bandage/rustle",CHAN_BODY,CHANF_OVERLAP);
		TNT1 A random(10,20);
		TNT1 A 0 A_JumpIf(IsMoving.Count(self)>=4,"abort");
		TNT1 A 0 A_Refire("try4");
		goto ready;
	try4:
		TNT1 A 0 A_MuzzleClimb(frandom(-1.8,1.8),frandom(-2.4,2.4));
		TNT1 A 0 A_Jump(8,"try2");
		TNT1 A 0 A_Jump(12,"try3");
	//	TNT1 A 0 A_Jump(16,"try4");
		TNT1 A 0 A_Jump(80,2);
		TNT1 A 0 A_StartSound("bandage/rustle",CHAN_BODY);
		TNT1 A random(10,20);
		TNT1 A 0 A_Jump(80,2);
		TNT1 A 0 A_StartSound("weapons/pocket",9);
		TNT1 A random(10,20);
		TNT1 A 0 A_JumpIf(IsMoving.Count(self)>=4,"abort");
		TNT1 A 0 A_JumpIf(!!hdbleedingwound.findbiggest(self,0),2);
		TNT1 A 0 {
			if(DoHelpText())A_WeaponMessage("You seem to be stable.",144);
		}goto nope;
		TNT1 A 0 A_Jump(42,2);
		TNT1 A 0 A_JumpIf(HDWoundFixer.CheckCovered(self,CHECKCOV_CHECKBODY),2);
		TNT1 A 4 A_Jump(100,2,3);
		TNT1 A 0 {invoker.bandagewound(frandom(2,6),self);invoker.weaponstatus[MEDS_GAUZE]--;}//covers wounds 2x better than rags
		//remove bandage "ammo" only once it treats a wound
		
		TNT1 A 0 A_MuzzleClimb(frandom(-2.4,2.4),frandom(-2.4,2.4));
		TNT1 A 0 A_Refire("try2");
		goto ready;
	nope:
		TNT1 A 0{invoker.targetlock=0;}
		goto super::nope;
	altfire:
	althold:
		TNT1 A 1;
		TNT1 A 0{
			actor a;int b;
			[a,b]=LineAttack(angle,42,pitch,0,"none",
				"CheckPuff",flags:LAF_NORANDOMPUFFZ|LAF_NOINTERACT
			);
			let c=a.tracer;
			if(!HDBleedingWound.canbleed(c)){
				A_WeaponMessage("Nothing to be done here.\n\nHeal thyself?");
				return resolvestate("nope");
			}
			if(IsMoving.Count(c)>4){
				c.A_Print(string.format("%s is trying to bandage you.\n\nStay still to let them or\ntell them to leave...",player.getusername()));
				A_WeaponMessage("You'll need them to stay still...");
				return resolvestate("nope");
			}
			if(!hdbleedingwound.findbiggest(c)){
				A_WeaponMessage("They're not bleeding.");
				return resolvestate("nope");
			}
			invoker.target=c;
			invoker.targetlock++;
			if(invoker.targetlock>10){
				A_Refire("injectbandage");
			}else A_Refire();
			return resolvestate(null);
		}goto nope;
	injectbandage:
		TNT1 A random(7,14){
			if(invoker.target){
				A_WeaponMessage("Working on "..HDMath.GetName(invoker.target).."...",20);
				if(random(0,2)){
					if(!random(0,2))invoker.target.A_StartSound("bandage/rustle",CHAN_BODY);
					return;
				}
				invoker.target.A_StartSound("weapons/pocket",CHAN_BODY,CHANF_OVERLAP);
				invoker.bandagewound(frandom(6,10),invoker.target);//2x better bandaging
			    invoker.weaponstatus[MEDS_GAUZE]--;
			}
		}goto ready;

	altreload:
		TNT1 A 0 A_StartSound("weapons/pocket",9);
		TNT1 A 15 A_JumpIf(!countinv("BloodBagWorn")||HDWoundFixer.CheckCovered(self,CHECKCOV_ONLYFULL),"nope");
		TNT1 A 10{
			A_SetBlend("7a 3a 18",0.1,4);
			A_MuzzleClimb(0,2);
			A_PlaySkinSound(SKINSOUND_MEDS,"*usemeds");
			A_DropInventory("BloodBagWorn");
		}
		goto nope;

	spawn:
		fmkt A -1;
		wait;
	}
}
