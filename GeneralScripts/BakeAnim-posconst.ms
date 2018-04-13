/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- bake animation
-- By ken turner
-- www.designimage.co.uk

-- dot net reference http://www.scriptspot.com/bobo/mxs9/dotNet/dotNetObject_System.Windows.Forms.TabControl.html
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- versions
-- 09/12/2017	v1.10 3dsmax 2017 rollout bug fix
-- 11 mar 2015 -- added help link , allowed user to delete keyframes in current time range as well as globally
*/------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--if KenzorsBakeAnim != undefined then KenzorsBakeAnim.closeup()
--KenzorsBakeAnim = undefined

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--fileIn ( "$userscripts/KenzorsScripts/Common/kenzorsRolloutManager.ms" )
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------BakeAnimRoll
rollout BakeAnimRoll "bake animation"
(
	Local isRolledOut = true --- required varible for kenzorsRolloutManager
	fn rolledUpEventFn =
	( --- required undefined varible for kenzorsRolloutManager
	)
	on BakeAnimRoll rolledUp val do ( isRolledOut = val ; rolledUpEventFn()) --- required function for kenzorsRolloutManager
	---------------------------------------------------------------------------------------------
	local fromObj = undefined
	local toObj = undefined
	Local OffsetTm = matrix3 1
	------------------------------------------------------------------------------------------
	group "pick objects"
	(
	PickButton BtnFrom "From" width:40 align:#left offset:[-5,0]
	Button btnFromObj ""	width:129 align:#left offset:[37,-26]
	PickButton BtnTo "onto" width:40  align:#left  offset:[-5,0]
	Button btnToObj "" width:129  align:#left offset:[37,-26]
	Label Lbl_flippedAxis
	)
	group ""
	(
	checkBox chkKeepOffset "KeepOffset" checked:false across:2--enabled:false 
	checkbox chk_Cat "CAT" checked:false 
		
	checkBox chkPosition "Pos" checked:true across:3
	checkBox chkRotation "Rot" checked:true
	checkBox chkScale "Scale" checked:false --enabled:false
	checkbox chkUnreal "rotate for unreal Hack (z-up)" checked:false
	)
	Button btnBakeCurrentFrame "Bake Current Frame" enabled:false
	group ""
	(
	checkBox chkRemoveKeysBeforeBaking "Remove Keys Before Baking" checked:true --enabled:false
	radiobuttons rBtnRange "" labels: #("All Keys", "Current time Range")

	Button BtnBake "Bake" width:80 across:2 enabled:false
	Spinner SpnStep "Step" range:[1,100,1] type:#integer fieldwidth:30 offset:[0,2]
	)
-----------------------------------------------------------------------------------
	group "Constraint" (
		checkbox chkconstPos "Position" checked:true across:2
		checkBox chkposOffset "PosOffset" checked:false


        checkbox chkconstRot "Rotation" checked:true across:2
        checkBox chkrotOffset "RotOffset" checked:false

        radiobuttons chkrot_world "" labels:#("world","local")


        Button chkconstraint "Constraint"
--------------------------------------------------------------------------------------
	)

	group ""
	(
		checkbox Sel_chk "Delete Select Key" checked:false
		checkbox Pos_chk "Pos" checked:false across:3
		checkbox Rot_chk "Rot" checked:false
		checkbox Scale_chk "Scale" checked:false
		button OK_btn "Delete"
	    -- Group body.
	)
	------------------------------------------------------------------------------------------------
	fn checkAndSelect theObj =
	(
		( if theObj !=undefined and (not isDeleted theObj) do select theObj )
	)
	fn checkNodesOK =
	(
		checkOK = fromObj !=undefined and (not isDeleted fromObj) and toObj !=undefined and (not isDeleted toObj) and fromObj != toObj
		if checkOK then OffsetTm = toObj.transform * inverse fromObj.transform
		btnBakeCurrentFrame.enabled = BtnBake.enabled = checkOK

		checkOK
	)
	fn checkObjectsHaveTheSameAxisOrder =
	(
		theCheck = if checkNodesOK() then
		(
			fromObj.transform.determinantsign == toObj.transform.determinantsign
		)else undefined
		Lbl_flippedAxis.text = (if theCheck == false then "warning: mirrored axis" else "" )
	)

	local mirrorTm =  (matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0])
	fn setMirrorTmWithAxisID i =
	(
		mirrorTm = case i of
		(
			0:(matrix3 [1,0,0] [0,1,0] [0,0,1] [0,0,0])
			1:(matrix3 [-1,0,0] [0,1,0] [0,0,1] [0,0,0])
			2:(matrix3 [1,0,0] [0,-1,0] [0,0,1] [0,0,0])
			3:(matrix3 [1,0,0] [0,1,0] [0,0,-1] [0,0,0])
		)
	)
	fn getTargetObjectTmWithOffset = ( OffsetTm * fromObj.transform)
	fn getTargetObjectTm = ( fromObj.transform )
	fn getMirroredTargetObjectTm = ( mirrorTm  * fromObj.transform )

	local ptrGetTargetObjectTm =  getTargetObjectTm

	On BtnFrom picked obj do ( btnFromObj.text = obj.name ; fromObj = obj ; checkNodesOK() ; checkObjectsHaveTheSameAxisOrder() )
	On BtnTo picked obj do ( btnToObj.text = obj.name ; toObj = obj ; checkNodesOK() ; checkObjectsHaveTheSameAxisOrder() )
	on btnFromObj pressed do checkAndSelect fromObj
	on btnToObj pressed do checkAndSelect toObj
	fn CollectKeysIndicesFrom theCtrl InTheRange:AnimationRange =  --- not used
	(
		n = theCtrl.keys.count
		for i = 1 to n where ( AnimationRange.start < theCtrl.keys.time ) and ( theCtrl.keys.time < AnimationRange.end ) collect i
	)
	fn RemoveKeysFromThisController theCtrl =
	(
		if rBtnRange.state == 1 then
		(
			deleteKeys theCtrl #allKeys  -- .keys
		)else
		(
			deleteTime theCtrl AnimationRange #noslide
		)
	)
	fn RemoveKeysFromTarget =
	(
		if chkRotation.checked then ( RemoveKeysFromThisController toObj.Rotation.controller )
		if chkPosition.checked then ( RemoveKeysFromThisController toObj.Position.controller )
		if chkScale.checked then ( RemoveKeysFromThisController toObj.scale.controller )
	)
	fn bakeAnimAtTime t UnrealTransform =
	(
		at time t
			(
				tm = ptrGetTargetObjectTm() * UnrealTransform
				if chkRotation.checked then ( with animate on ( toObj.Rotation = inverse tm.rotation ) )
				if chkPosition.checked then ( with animate on ( toObj.position = tm.position ) )
				if chkScale.checked then ( with animate on ( toObj.scale = tm.scale ) )
				--------------------------------------------
				if chk_Cat.checked then ( with animate on ( toObj.Transform = tm) )
			)
	)
	fn getUnrealTm =
	(
		if chkUnreal.checked then  (( eulerangles 0 0 -90  ) as matrix3 ) else ( matrix3 1 )
	)
	fn BakeTheAnim =
	(
		-- UnrealTransform = if chkUnreal.checked then  (( eulerangles 0 0 -90  ) as matrix3 ) else ( matrix3 1 )
		UnrealTransform = getUnrealTm()
		for t = animationrange.start to animationrange.end by SpnStep.value do
		(
			bakeAnimAtTime t UnrealTransform
/* 			at time t
* 			(
* 				tm = ptrGetTargetObjectTm() * UnrealTransform
* 				if chkRotation.checked then ( with animate on ( toObj.Rotation = inverse tm.rotation ) )
* 				if chkPosition.checked then ( with animate on ( toObj.position = tm.position ) )
* 				if chkScale.checked then ( with animate on ( toObj.scale = tm.scale ) )
* 			)
*/
		)
	)
	on chkKeepOffset changed KeepOffsetTrue do
	(
		ptrGetTargetObjectTm = if KeepOffsetTrue then getTargetObjectTmWithOffset else getTargetObjectTm
	)
	on chkRemoveKeysBeforeBaking changed state do rBtnRange.enabled = state
	---------------------------------------------------------------------------
	on chkconstPos changed state do chkposOffset.enabled = state
	on chkconstRot changed state do chkrotOffset.enabled = chkrot_world.enabled = state
	---------------------------------------------------------------------------
	on BtnBake pressed do
	(
		if checkNodesOK() do
		(
			if chkRemoveKeysBeforeBaking.checked do RemoveKeysFromTarget()
			BakeTheAnim()
		)
	)
	on btnBakeCurrentFrame pressed do
	(
		if checkNodesOK() do
		(
			bakeAnimAtTime (currentTime.frame)  (getUnrealTm())
		)
	)

-----------------------------------------------------------------------------Constraint

    on chkconstraint pressed do
    (
    	if checkNodesOK() do
    	(
    		undo on
    		(
	    		if chkconstPos.checked == true then
	    		(
	    			fromObj.pos.controller = position_list ()
	    			fromObj.pos.controller.Available.controller = Position_Constraint ()
	    			fromObj.pos.controller.SetActive 2
	    			fromObj.pos.controller.Position_Constraint.appendTarget toObj 50.0
					if chkposOffset.checked ==true then
						fromObj.pos.controller.Position_Constraint.controller.RELATIVE = on

				)

				if chkconstRot.checked == true then
				(
					fromObj.rotation.controller = rotation_list ()
					fromObj.rotation.controller.Available.controller = Orientation_Constraint ()
					fromObj.rotation.controller.SetActive 2
					fromObj.rotation.controller.Orientation_Constraint.appendTarget toObj 50
					if chkrotOffset.checked ==true then
						fromObj.rotation.controller.Orientation_Constraint.controller.RELATIVE = on
					if chkrot_world.state ==2 then
						fromObj.rotation.controller.Orientation_Constraint.controller.local_world = 1
				)
			)
    	)


    )
-------------------------------------------------------------------------------------------------
	-----delete select key
		fn Default_IO IO_Class=
		(
			if IO_Class == "Input" do
			(
				try
				(
					Pos_chk.checked				= 		Default_Setting[1]
					Rot_chk.checked				= 		Default_Setting[2]
					Scale_chk.checked 				= 		Default_Setting[3]
					Sel_chk.checked				=		Default_Setting[4]
				)
				catch()

			)
			if IO_Class == "Output" do
			(
				Default_Setting[1] 			=		Pos_chk.checked
				Default_Setting[2] 			=		Rot_chk.checked
				Default_Setting[3] 			=		Scale_chk.checked
				Default_Setting[4]				= 		Sel_chk.checked
			)
		)

		on delSelKeys_Rollout open do
		(
			Default_IO "Input"
		)
		on delSelKeys_Rollout close do
		(
			Default_IO "Output"
			--FnPrint()
		)

		fn delRot a =
		(
		deselectKeys a
		selectKeys a.rotation.controller
		deleteKeys a #selection
		)

		fn delPos b =
		(
		deselectKeys b
		selectKeys b.pos.controller
		deleteKeys b #selection
		)

		fn delScale c =
		(
		deselectKeys c
		selectKeys c.scale.controller
		deleteKeys c #selection
		)

		on OK_btn pressed do
		(
			objKeys = selection as array
			undo on
			(
				if Sel_chk.checked then
				(
					if Rot_chk.checked  do
					(
					for f = 1 to objKeys.count do (deleteKeys objKeys[f].rotation.controller #selection)
					)

					if Pos_chk.checked  do
					(
					for g = 1 to objKeys.count do (deleteKeys objKeys[g].pos.controller #selection)
					)

					if Scale_chk.checked  do
					(
					for h = 1 to objKeys.count do (deleteKeys objKeys[h].scale.controller #selection)
					)
				)
				else
				(
					if Rot_chk.checked  do
					(
					for j = 1 to objKeys.count do delRot objKeys[j]
					)

					if Pos_chk.checked  do
					(
					for k = 1 to objKeys.count do delPos objKeys[k]
					)

					if Scale_chk.checked  do
					(
					for l = 1 to objKeys.count do delScale objKeys[l]
					)
				)
			)
		)


)
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------------------- END OF: BakeAnimRoll

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CreateDialog BakeAnimRoll width:200
--KenzorsBakeAnim.Initalize()
--KenzorsAboutMeRoll.wwwHelp = "http://www.designimage.co.uk/kenzors-maxscripts-bake-anim/"