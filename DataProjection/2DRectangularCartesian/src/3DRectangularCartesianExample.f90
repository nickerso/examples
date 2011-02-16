!> \file
!> $Id: 3DRectangularCartesianExample.f90 1528 2010-09-21 01:32:29Z chrispbradley $
!> \author Tim Wu
!> \brief This is an example program to solve 3D data points embedding in 3D cartesian elements using openCMISS calls.
!>
!> \section LICENSE
!>
!> Version: MPL 1.1/GPL 2.0/LGPL 2.1
!>
!> The contents of this file are subject to the Mozilla Public License
!> Version 1.1 (the "License"); you may not use this file except in
!> compliance with the License. You may obtain a copy of the License at
!> http://www.mozilla.org/MPL/
!>
!> Software distributed under the License is distributed on an "AS IS"
!> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
!> License for the specific language governing rights and limitations
!> under the License.
!>
!> The Original Code is openCMISS
!>
!> The Initial Developer of the Original Code is University of Auckland,
!> Auckland, New Zealand and University of Oxford, Oxford, United
!> Kingdom. Portions created by the University of Auckland and University
!> of Oxford are Copyright (C) 2007 by the University of Auckland and
!> the University of Oxford. All Rights Reserved.
!>
!> Contributor(s): Code based on the examples by Kumar Mithraratne and Prasad Babarenda Gamage
!>
!> Alternatively, the contents of this file may be used under the terms of
!> either the GNU General Public License Version 2 or later (the "GPL"), or
!> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
!> in which case the provisions of the GPL or the LGPL are applicable instead
!> of those above. If you wish to allow use of your version of this file only
!> under the terms of either the GPL or the LGPL, and not to allow others to
!> use your version of this file under the terms of the MPL, indicate your
!> decision by deleting the provisions above and replace them with the notice
!> and other provisions required by the GPL or the LGPL. If you do not delete
!> the provisions above, a recipient may use your version of this file under
!> the terms of any one of the MPL, the GPL or the LGPL.

!> Main program
PROGRAM DataProjection1DRectangularCartesian

  USE MPI
  USE OPENCMISS

#ifdef WIN32
  USE IFQWIN
#endif

  IMPLICIT NONE

  !Program parameters
  INTEGER(CMISSIntg),PARAMETER :: BasisUserNumber=1  
  INTEGER(CMISSIntg),PARAMETER :: CoordinateSystemDimension=3
  INTEGER(CMISSIntg),PARAMETER :: CoordinateSystemUserNumber=1
  INTEGER(CMISSIntg),PARAMETER :: DecompositionUserNumber=1
  INTEGER(CMISSIntg),PARAMETER :: FieldUserNumber=1  
  INTEGER(CMISSIntg),PARAMETER :: MeshUserNumber=1
  INTEGER(CMISSIntg),PARAMETER :: RegionUserNumber=1

  REAL(CMISSDP), PARAMETER :: CoordinateSystemOrigin(3)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/)  
  !Program types

  !Program variables   
  INTEGER(CMISSIntg) :: MeshComponentNumber=1
  INTEGER(CMISSIntg) :: NumberOfDataPoints 
  INTEGER(CMISSIntg) :: MeshDimensions=3
  INTEGER(CMISSIntg) :: MeshNumberOfElements
  INTEGER(CMISSIntg) :: MeshNumberOfComponents=1
  INTEGER(CMISSIntg) :: NumberOfDomains=1 !NumberOfDomains=2 for parallel processing, need to set up MPI
  INTEGER(CMISSIntg) :: NumberOfNodes
  INTEGER(CMISSIntg) :: NumberOfXi=3
  INTEGER(CMISSIntg) :: BasisInterpolation(3)=(/CMISSBasisCubicHermiteInterpolation,CMISSBasisCubicHermiteInterpolation, &
    & CMISSBasisCubicHermiteInterpolation/)
  INTEGER(CMISSIntg) :: WorldCoordinateSystemUserNumber
  INTEGER(CMISSIntg) :: WorldRegionUserNumber
  
  INTEGER(CMISSIntg) :: FieldNumberOfVariables=1
  INTEGER(CMISSIntg) :: FieldNumberOfComponents=3 
  

  INTEGER(CMISSIntg) :: np,el,der_idx,node_idx,comp_idx
    
  REAL(CMISSDP), DIMENSION(5,3) :: DataPointValues !(number_of_data_points,dimension)
  REAL(CMISSDP), DIMENSION(5) :: DataPointProjectionDistance !(number_of_data_points)
  INTEGER(CMISSIntg), DIMENSION(5) :: DataPointProjectionElementNumber !(number_of_data_points)
  INTEGER(CMISSIntg), DIMENSION(5) :: DataPointProjectionExitTag !(number_of_data_points)
  REAL(CMISSDP), DIMENSION(5,3) :: DataPointProjectionXi !(number_of_data_points,MeshDimensions)  
  INTEGER(CMISSIntg), DIMENSION(1,8) :: ElementUserNodes  
  REAL(CMISSDP), DIMENSION(8,8,3) :: FieldValues
        
#ifdef WIN32
  !Quickwin type
  LOGICAL :: QUICKWIN_STATUS=.FALSE.
  TYPE(WINDOWCONFIG) :: QUICKWIN_WINDOW_CONFIG
#endif

  !Generic CMISS and MPI variables
  INTEGER(CMISSIntg) :: Err
  INTEGER(CMISSIntg) :: NUMBER_GLOBAL_X_ELEMENTS=1 !<number of elements on x axis
  INTEGER(CMISSIntg) :: NUMBER_GLOBAL_Y_ELEMENTS=1 !<number of elements on y axis
  INTEGER(CMISSIntg) :: NUMBER_GLOBAL_Z_ELEMENTS=1 !<number of elements on z axis  
  INTEGER(CMISSIntg) :: NUMBER_OF_DOMAINS=1      
  INTEGER(CMISSIntg) :: MPI_IERROR  
  
#ifdef WIN32
  !Initialise QuickWin
  QUICKWIN_WINDOW_CONFIG%TITLE="General Output" !Window title
  QUICKWIN_WINDOW_CONFIG%NUMTEXTROWS=-1 !Max possible number of rows
  QUICKWIN_WINDOW_CONFIG%MODE=QWIN$SCROLLDOWN
  !Set the window parameters
  QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
  !If attempt fails set with system estimated values
  IF(.NOT.QUICKWIN_STATUS) QUICKWIN_STATUS=SETWINDOWCONFIG(QUICKWIN_WINDOW_CONFIG)
#endif
    
  !Intialise 5 data points
  DataPointValues(1,:)=(/0.1_CMISSDP,0.8_CMISSDP,1.0_CMISSDP/)
  DataPointValues(2,:)=(/0.5_CMISSDP,0.5_CMISSDP,0.5_CMISSDP/)  
  DataPointValues(3,:)=(/0.2_CMISSDP,0.5_CMISSDP,0.5_CMISSDP/)  
  DataPointValues(4,:)=(/0.9_CMISSDP,0.6_CMISSDP,0.9_CMISSDP/)
  DataPointValues(5,:)=(/0.3_CMISSDP,0.3_CMISSDP,0.3_CMISSDP/)
  NumberOfDataPoints=SIZE(DataPointValues,1)
  
  !Intialise 1 element
  ElementUserNodes(1,:)=(/1,2,3,4,5,6,7,8/)     
  MeshNumberOfElements=SIZE(ElementUserNodes,1)
  
  !Intialise 8 nodes for the element
  FieldValues(1,1,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !no der, node 1
  FieldValues(2,1,:)=(/1.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 der, node 1
  FieldValues(3,1,:)=(/0.0_CMISSDP,1.0_CMISSDP,0.0_CMISSDP/) !s2 der, node 1  
  FieldValues(4,1,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s2 der, node 1    
  FieldValues(5,1,:)=(/0.0_CMISSDP,0.0_CMISSDP,1.0_CMISSDP/) !s3 der, node 1
  FieldValues(6,1,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s3 der, node 1  
  FieldValues(7,1,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s2 s3 der, node 1    
  FieldValues(8,1,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s2 s3 der, node 1    
  
  FieldValues(1,2,:)=(/1.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !no der, node 2
  FieldValues(2,2,:)=(/1.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 der, node 2
  FieldValues(3,2,:)=(/0.0_CMISSDP,1.0_CMISSDP,0.0_CMISSDP/) !s2 der, node 2  
  FieldValues(4,2,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s2 der, node 2    
  FieldValues(5,2,:)=(/0.0_CMISSDP,0.0_CMISSDP,1.0_CMISSDP/) !s3 der, node 2
  FieldValues(6,2,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s3 der, node 2  
  FieldValues(7,2,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s2 s3 der, node 2    
  FieldValues(8,2,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s2 s3 der, node 2     
  
  FieldValues(1,3,:)=(/0.0_CMISSDP,1.0_CMISSDP,0.0_CMISSDP/) !no der, node 3
  FieldValues(2,3,:)=(/1.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 der, node 3
  FieldValues(3,3,:)=(/0.0_CMISSDP,1.0_CMISSDP,0.0_CMISSDP/) !s2 der, node 3  
  FieldValues(4,3,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s2 der, node 3    
  FieldValues(5,3,:)=(/0.0_CMISSDP,0.0_CMISSDP,1.0_CMISSDP/) !s3 der, node 3
  FieldValues(6,3,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s3 der, node 3  
  FieldValues(7,3,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s2 s3 der, node 3    
  FieldValues(8,3,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s2 s3 der, node 3
  
  FieldValues(1,4,:)=(/1.0_CMISSDP,1.0_CMISSDP,0.0_CMISSDP/) !no der, node 4
  FieldValues(2,4,:)=(/1.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 der, node 4
  FieldValues(3,4,:)=(/0.0_CMISSDP,1.0_CMISSDP,0.0_CMISSDP/) !s2 der, node 4  
  FieldValues(4,4,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s2 der, node 4    
  FieldValues(5,4,:)=(/0.0_CMISSDP,0.0_CMISSDP,1.0_CMISSDP/) !s3 der, node 4
  FieldValues(6,4,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s3 der, node 4  
  FieldValues(7,4,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s2 s3 der, node 4    
  FieldValues(8,4,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s2 s3 der, node 4
  
  FieldValues(1,5,:)=(/0.0_CMISSDP,0.0_CMISSDP,1.0_CMISSDP/) !no der, node 5
  FieldValues(2,5,:)=(/1.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 der, node 5
  FieldValues(3,5,:)=(/0.0_CMISSDP,1.0_CMISSDP,0.0_CMISSDP/) !s2 der, node 5  
  FieldValues(4,5,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s2 der, node 5    
  FieldValues(5,5,:)=(/0.0_CMISSDP,0.0_CMISSDP,1.0_CMISSDP/) !s3 der, node 5
  FieldValues(6,5,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s3 der, node 5  
  FieldValues(7,5,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s2 s3 der, node 5    
  FieldValues(8,5,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s2 s3 der, node 5    
  
  FieldValues(1,6,:)=(/1.0_CMISSDP,0.0_CMISSDP,1.0_CMISSDP/) !no der, node 6
  FieldValues(2,6,:)=(/1.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 der, node 6
  FieldValues(3,6,:)=(/0.0_CMISSDP,1.0_CMISSDP,0.0_CMISSDP/) !s2 der, node 6  
  FieldValues(4,6,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s2 der, node 6    
  FieldValues(5,6,:)=(/0.0_CMISSDP,0.0_CMISSDP,1.0_CMISSDP/) !s3 der, node 6
  FieldValues(6,6,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s3 der, node 6  
  FieldValues(7,6,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s2 s3 der, node 6    
  FieldValues(8,6,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s2 s3 der, node 6     
  
  FieldValues(1,7,:)=(/0.0_CMISSDP,1.0_CMISSDP,1.0_CMISSDP/) !no der, node 7
  FieldValues(2,7,:)=(/1.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 der, node 7
  FieldValues(3,7,:)=(/0.0_CMISSDP,1.0_CMISSDP,0.0_CMISSDP/) !s2 der, node 7  
  FieldValues(4,7,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s2 der, node 7    
  FieldValues(5,7,:)=(/0.0_CMISSDP,0.0_CMISSDP,1.0_CMISSDP/) !s3 der, node 7
  FieldValues(6,7,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s3 der, node 7  
  FieldValues(7,7,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s2 s3 der, node 7    
  FieldValues(8,7,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s2 s3 der, node 7
  
  FieldValues(1,8,:)=(/1.0_CMISSDP,1.0_CMISSDP,1.0_CMISSDP/) !no der, node 8
  FieldValues(2,8,:)=(/1.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 der, node 8
  FieldValues(3,8,:)=(/0.0_CMISSDP,1.0_CMISSDP,0.0_CMISSDP/) !s2 der, node 8  
  FieldValues(4,8,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s2 der, node 8    
  FieldValues(5,8,:)=(/0.0_CMISSDP,0.0_CMISSDP,1.0_CMISSDP/) !s3 der, node 8
  FieldValues(6,8,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s3 der, node 8  
  FieldValues(7,8,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s2 s3 der, node 8    
  FieldValues(8,8,:)=(/0.0_CMISSDP,0.0_CMISSDP,0.0_CMISSDP/) !s1 s2 s3 der, node 8
  NumberOfNodes=SIZE(FieldValues,2)
  
  !Intialise cmiss
  CALL CMISSInitialise(WorldCoordinateSystemUserNumber,WorldRegionUserNumber,Err)
  !Broadcast the number of Elements in the X & Y directions and the number of partitions to the other computational nodes
  CALL MPI_BCAST(NUMBER_GLOBAL_X_ELEMENTS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
  CALL MPI_BCAST(NUMBER_GLOBAL_Y_ELEMENTS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
  CALL MPI_BCAST(NUMBER_GLOBAL_Z_ELEMENTS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)
  CALL MPI_BCAST(NUMBER_OF_DOMAINS,1,MPI_INTEGER,0,MPI_COMM_WORLD,MPI_IERROR)

  !=========================================================================================================================
  !Create RC coordinate system
  CALL CMISSCoordinateSystemCreateStart(CoordinateSystemUserNumber,Err)
  CALL CMISSCoordinateSystemTypeSet(CoordinateSystemUserNumber,CMISSCoordinateRectangularCartesianType,Err)
  CALL CMISSCoordinateSystemDimensionSet(CoordinateSystemUserNumber,CoordinateSystemDimension,Err)
  CALL CMISSCoordinateSystemOriginSet(CoordinateSystemUserNumber,CoordinateSystemOrigin,Err)
  CALL CMISSCoordinateSystemCreateFinish(CoordinateSystemUserNumber,Err) 

  !=========================================================================================================================
  !Create Region and set CS to newly created 3D RC CS
  CALL CMISSRegionCreateStart(RegionUserNumber,WorldRegionUserNumber,Err)
  CALL CMISSRegionCoordinateSystemSet(RegionUserNumber,CoordinateSystemUserNumber,Err)
  CALL CMISSRegionCreateFinish(RegionUserNumber,Err)
    
  !=========================================================================================================================
  !Create Data Points and set the values
  CALL CMISSDataPointsCreateStart(RegionUserNumber,SIZE(DataPointValues,1),Err)
  DO np=1,NumberOfDataPoints
    CALL CMISSDataPointsValuesSet(RegionUserNumber,np,DataPointValues(np,:),Err)     
  ENDDO
  CALL CMISSDataPointsCreateFinish(RegionUserNumber,Err)  
  !=========================================================================================================================
  !Define basis function - 1D cubic hermite
  CALL CMISSBasisCreateStart(BasisUserNumber,Err)
  CALL CMISSBasisTypeSet(BasisUserNumber,CMISSBasisLagrangeHermiteTPType,Err)
  CALL CMISSBasisNumberOfXiSet(BasisUserNumber,NumberOfXi,Err)
  CALL CMISSBasisInterpolationXiSet(BasisUserNumber,BasisInterpolation,Err)
  CALL CMISSBasisCreateFinish(BasisUserNumber,Err)  
  !=========================================================================================================================
  !Create a mesh
  CALL CMISSMeshCreateStart(MeshUserNumber,RegionUserNumber,MeshDimensions,Err)
  CALL CMISSMeshNumberOfComponentsSet(RegionUserNumber,MeshUserNumber,MeshNumberOfComponents,Err)
  CALL CMISSMeshNumberOfElementsSet(RegionUserNumber,MeshUserNumber,MeshNumberOfElements,Err)
  !define nodes for the mesh
  CALL CMISSNodesCreateStart(RegionUserNumber,NumberOfNodes,Err)
  CALL CMISSNodesCreateFinish(RegionUserNumber,Err)  
  !define elements for the mesh
  CALL CMISSMeshElementsCreateStart(RegionUserNumber,MeshUserNumber,MeshComponentNumber,BasisUserNumber,Err)
  Do el=1,MeshNumberOfElements
    CALL CMISSMeshElementsNodesSet(RegionUserNumber,MeshUserNumber,MeshComponentNumber,el,ElementUserNodes(el,:),Err)
  ENDDO
  CALL CMISSMeshElementsCreateFinish(RegionUserNumber,MeshUserNumber,MeshComponentNumber,Err)
  CALL CMISSMeshCreateFinish(RegionUserNumber,MeshUserNumber,Err)
  !=========================================================================================================================
  !Create a mesh decomposition 
  CALL CMISSDecompositionCreateStart(DecompositionUserNumber,RegionUserNumber,MeshUserNumber,Err)
  CALL CMISSDecompositionTypeSet(RegionUserNumber,MeshUserNumber,DecompositionUserNumber,CMISSDecompositionCalculatedType,Err)
  CALL CMISSDecompositionNumberOfDomainsSet(RegionUserNumber,MeshUserNumber,DecompositionUserNumber,NumberOfDomains,Err)
  CALL CMISSDecompositionCreateFinish(RegionUserNumber,MeshUserNumber,DecompositionUserNumber,Err)
  
  !=========================================================================================================================
  !Create a field to put the geometry
  CALL CMISSFieldCreateStart(FieldUserNumber,RegionUserNumber,Err)
  CALL CMISSFieldMeshDecompositionSet(RegionUserNumber,FieldUserNumber,MeshUserNumber,DecompositionUserNumber,Err)
  CALL CMISSFieldTypeSet(RegionUserNumber,FieldUserNumber,CMISSFieldGeometricType,Err)
  CALL CMISSFieldNumberOfVariablesSet(RegionUserNumber,FieldUserNumber,FieldNumberOfVariables,Err)
  CALL CMISSFieldNumberOfComponentsSet(RegionUserNumber,FieldUserNumber,CMISSFieldUVariableType,FieldNumberOfComponents,Err)
  CALL CMISSFieldComponentMeshComponentSet(RegionUserNumber,FieldUserNumber,CMISSFieldUVariableType,1,1,Err)
!  DO xi=1,NumberOfXi
    
!  ENDDO !xi    
  CALL CMISSFieldCreateFinish(RegionUserNumber,FieldUserNumber,Err)
  !node 1
  DO der_idx=1,SIZE(FieldValues,1)
    DO node_idx=1,SIZE(FieldValues,2)
      DO comp_idx=1,SIZE(FieldValues,3)
        CALL CMISSFieldParameterSetUpdateNode(RegionUserNumber,FieldUserNumber,CMISSFieldUVariableType,CMISSFieldValuesSetType, &
          & der_idx,node_idx,comp_idx,FieldValues(der_idx,node_idx,comp_idx),Err)
      ENDDO
    ENDDO
  ENDDO
  
  !=========================================================================================================================
  !Create a data projection
  CALL CMISSDataProjectionCreateStart(RegionUserNumber,FieldUserNumber,RegionUserNumber,Err)
  CALL CMISSDataProjectionProjectionTypeSet(RegionUserNumber,CMISSDataProjectionAllElementsProjectionType,Err) !Set to element projection for data points embedding. The default is boundary/surface projection.
  CALL CMISSDataProjectionCreateFinish(RegionUserNumber,Err)
  
  !=========================================================================================================================
  !Start data projection
  CALL CMISSDataProjectionEvaluate(RegionUserNumber,Err)

  !Retrieve projection results
  DO np=1,NumberOfDataPoints
    CALL CMISSDataPointsProjectionDistanceGet(RegionUserNumber,np,DataPointProjectionDistance(np),Err)
    CALL CMISSDataPointsProjectionElementNumberGet(RegionUserNumber,np,DataPointProjectionElementNumber(np),Err)
    CALL CMISSDataPointsProjectionExitTagGet(RegionUserNumber,np,DataPointProjectionExitTag(np),Err)
    CALL CMISSDataPointsProjectionXiGet(RegionUserNumber,np,DataPointProjectionXi(np,:),Err)
  ENDDO  
  
  !=========================================================================================================================
  !Destroy used types
  CALL CMISSDataProjectionDestroy(RegionUserNumber,Err)
  CALL CMISSDataPointsDestroy(RegionUserNumber,Err)
    
  CALL CMISSRegionDestroy(RegionUserNumber,Err)
  CALL CMISSCoordinateSystemDestroy(CoordinateSystemUserNumber,Err)  
  
  !=========================================================================================================================
  !Finishing program
  CALL CMISSFinalise(Err)
  WRITE(*,'(A)') "Program successfully completed."
  STOP  
  
END PROGRAM DataProjection1DRectangularCartesian
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
