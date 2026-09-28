import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import LEAFLET from '@salesforce/resourceUrl/LEAFLET';
import US_STATES_GEOJSON from '@salesforce/resourceUrl/US_STATES_JSON';
import getSuperDistricts from '@salesforce/apex/CescoSuperDistrictMapController.getSuperDistricts';
import getAgenciesForSuperDistrict from '@salesforce/apex/CescoSuperDistrictMapController.getAgenciesForSuperDistrict';
import getAgencySuppliers from '@salesforce/apex/CescoSuperDistrictMapController.getAgencySuppliers';
import getSupplierAgencies from '@salesforce/apex/CescoSuperDistrictMapController.getSupplierAgencies'
import getAgencies from '@salesforce/apex/CescoSuperDistrictMapController.getAgencies'
import getAccount from '@salesforce/apex/CescoSuperDistrictMapController.getAccount'

const CONTACT_COLUMNS = [
    { label: 'Name', fieldName: 'contactUrl', type: 'url',
      typeAttributes: { label: { fieldName: 'Full_Name__c' }, target: '_blank' } },
    { label: 'Email', fieldName: 'Email', type: 'email' },
    { label: 'Phone', fieldName: 'Phone', type: 'phone' }
];

export default class CescoAgencyMap extends  NavigationMixin(LightningElement) {
    contactColumns = CONTACT_COLUMNS;
    map;
    leafletInitialized = false;
    districtMap = new Map();
    agencyMarkers = [];
    agencyLocationMap = new Map();
    @track mapStyle = "height:500px;width:100%;max-height:500px;";
    @track agencyDetail;
    @track agencyDetails;
    @track agencyList = null;
    @track agencySearch = '';
    @track supplierList = null;
    @track supplierSearch = '';
    @track selectedSuperDistrict = null;
    @track supplierAccount = null;
    @track hasContacts = false;
    @track isMobile = false;
    defaultZoom = 4.5;
    centerUsLat = 39.9283;
    centerUsLon =  -98.5795;
    statesGeoJsonData;
    
  

    get dynamicMapStyle() {
        return this.mapStyle;
    }

    async renderedCallback() {        
        if (this.leafletInitialized) {
            return;
        }
        this.leafletInitialized = true;

        Promise.all([
            loadScript(this, LEAFLET + '/leaflet.js'),
            loadStyle(this, LEAFLET + '/leaflet.css')
        ])
        .then(() => {
            this.setMap(this.centerUsLat, this.centerUsLon, this.defaultZoom);//center of cont u.s.
            this.loadMarkers();  
        })
        .catch(error => {
            console.error('Error loading Leaflet', error);
            this.showErrorToast();
        });
        try {
            const statesFileUrl = `${US_STATES_GEOJSON}/us-states.json`;
            const statesGeoResponse = await fetch(statesFileUrl);
            this.statesGeoJsonData = await statesGeoResponse.json();
        } catch (err) {
            this.error = err.message;
        }
    }

    setMap(lat, lng, zoom) {
        let maxZoom = 19;        
        try{
            const mapElement = this.template.querySelector('.map');
            if(!this.map){
                this.map = L.map(
                    mapElement,
                     {zoomSnap: 0.25, zoomDelta: 0.25}).setView([lat,lng], zoom);
                L.tileLayer(
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    {
                        attribution: '&copy; OpenStreetMap contributors',
                        maxZoom: maxZoom
                    }).addTo(this.map);
            }else{
                this.map.setView([lat, lng], zoom);
            }
            this.map.attributionControl.setPrefix('');
            this.map.doubleClickZoom.disable();            
            this.map.touchZoom.disable(); 
            this.isMobile = L.Browser.mobile; 


            //TODO Testing ZOOM

            const zoomLabel = L.control({ position: 'bottomright' });

            zoomLabel.onAdd = function (map) {
                this._div = L.DomUtil.create('div', 'zoom-label');
                this._div.style.background = 'white';
                this._div.style.padding = '4px 8px';
                this._div.style.borderRadius = '4px';
                this.update(map.getZoom());
                return this._div;
            };

            zoomLabel.update = function (zoom) {
            this._div.innerHTML = `Zoom: ${zoom}`;
            };

            zoomLabel.addTo(this.map);

            this.map.on('zoomend', () => {
            zoomLabel.update(this.map.getZoom());
            });
        }
        catch(error){
            console.log(error);
            this.showErrorToast();
        }
    }

    loadMarkers() {
        getSuperDistricts()
            .then(data => {
                this.districtMap = new Map(
                    data.map(d => [d.SuperDistrictID__c, d])
                );                
                let markerLabelFontSize = '.75rem';               
                const bounds = [];
                data.forEach(district => {                    
                    const lat = district.Geolocation__Latitude__s;
                    const lng = district.Geolocation__Longitude__s;
                    if (!lat || !lng) {
                        return;
                    }
                    const labelIcon = L.divIcon({   
                        className: '',                    
                        html: `<span  style='font-size:${markerLabelFontSize};font-weight: bold; text-align:center;color:${district.Html_Color__c}; border: none;'>${district.Name.replaceAll('SUPER DIST', '').trim()}</span>`,
                        iconSize: [150, 30],
                        iconAnchor: [0, 0]
                    });                  
                    const marker = L.marker([lat, lng], {
                        icon: labelIcon
                    }).addTo(this.map);

                    marker.on('click', () => {
                        this.handleSuperDistrictClick(
                            district.SuperDistrictID__c
                        );
                     });
                    bounds.push([lat, lng]);
                    this.setMapBorderForSuperDistrict(district.SuperDistrictID__c, district.Html_Fore_Color__c);
                }); 

            })
            .catch(error => {
                console.error(error);
                this.showErrorToast();
            });
    }
    setMapBorderForSuperDistrict(superDistrict, color){
        switch(superDistrict){
            case 'SDBIGSKY':{
                L.geoJSON(this.statesGeoJsonData, {
                                filter: feature =>
                                ['Montana', 'Idaho'].includes(feature.properties.name),
                                style: {
                                    color: color,
                                    opacity: 0.25,
                                    fillOpacity: .25
                                }
                            }).addTo(this.map);
                            return;
            }
            case 'SDCASCAD':{
                L.geoJSON(this.statesGeoJsonData, {
                        filter: feature =>
                        ['Washington'].includes(feature.properties.name),
                        style: {
                            color: color,
                            opacity: 0.25,
                            fillOpacity: .40
                    }
                }).addTo(this.map);
                 return;
            }
            case 'SDGLAKES':{
                L.geoJSON(this.statesGeoJsonData, {
                        filter: feature =>
                        ['Michigan', 'Pennsylvania', 'Ohio'].includes(feature.properties.name),
                        style: {
                            color: color,
                            weight: 3,
                            opacity: 0.25,
                            fillOpacity: .4
                    }
                }).addTo(this.map);
                 return;
            }
             case 'SDGPLAIN':{
                L.geoJSON(this.statesGeoJsonData, {
                        filter: feature =>
                        ['Kansas', 'Nebraska'].includes(feature.properties.name),
                        style: {
                            color: color,
                            opacity: 0.25,
                            fillOpacity: .4
                    }
                }).addTo(this.map);
                 return;
            }
             case 'SDLOWE':{
                L.geoJSON(this.statesGeoJsonData, {
                        filter: feature =>
                        ['Georgia', 'South Carolina'].includes(feature.properties.name),
                        style: {
                            color: color,
                            opacity: 0.25,
                            fillOpacity: .4
                    }
                }).addTo(this.map);
                 return;
            }
             case 'SDMIDATL':{
                L.geoJSON(this.statesGeoJsonData, {
                        filter: feature =>
                        ['North Carolina', 'Virginia'].includes(feature.properties.name),
                        style: {
                            color: color,
                            weight: 3,
                            opacity: 0.25,
                            fillOpacity: .1
                    }
                }).addTo(this.map);
                 return;
            }
             case 'SDNCENTR':{
                L.geoJSON(this.statesGeoJsonData, {
                        filter: feature =>
                        ['Illinois', 'Wisconsin'].includes(feature.properties.name),
                        style: {
                            color: color,
                            weight: 3,
                            opacity: 0.25,
                            fillOpacity: .1
                    }
                }).addTo(this.map);
                 return;
            }
             case 'SDNPACIF':{
                L.geoJSON(this.statesGeoJsonData, {
                        filter: feature =>
                        ['Oregon', 'Alaska'].includes(feature.properties.name),
                        style: {
                            color: color,
                            opacity: .25,
                            fillOpacity: .40
                    }
                }).addTo(this.map);
                 return;
            }
             case 'SDNPLAIN':{
                L.geoJSON(this.statesGeoJsonData, {
                        filter: feature =>
                        ['Minnesota', 'Iowa','North Dakota'].includes(feature.properties.name),
                        style: {
                            color: color,
                            weight: 3,
                            opacity: 0.25,
                            fillOpacity: .1
                    }
                }).addTo(this.map);
                 return;
            }
             case 'SDRIVERV':{
                L.geoJSON(this.statesGeoJsonData, {
                        filter: feature =>
                        ['Indiana', 'Kentucky'].includes(feature.properties.name),
                        style: {
                            color: color,
                            weight: 3,
                            opacity: 0.25,
                            fillOpacity: .1
                    }
                }).addTo(this.map);
                 return;
            }
            case 'SDROCKMN':{
                L.geoJSON(this.statesGeoJsonData, {
                        filter: feature =>
                        ['Colorado', 'South Dakota', 'Wyoming'].includes(feature.properties.name),
                        style: {
                            color: color,
                            opacity: 0.25,
                            fillOpacity: .40
                    }
                }).addTo(this.map);
                 return;
            }
            case 'SDSWEST':{
                L.geoJSON(this.statesGeoJsonData, {
                        filter: feature =>
                        ['Arizona', 'Utah', 'Nevada', 'Texas', 'New Mexico'].includes(feature.properties.name),
                        style: {
                            color: color,
                            opacity: 0.25,
                            fillOpacity: .5
                    }
                }).addTo(this.map);
                 return;
            }
        }

    }
    get filteredSuppliers() {
        if (!this.supplierList) return [];
        const q = this.supplierSearch.toLowerCase();
        return q
            ? this.supplierList.filter(s => s.name.toLowerCase().includes(q))
            : this.supplierList;
    }

    get noSupplierResults() {
        return this.supplierList && this.supplierList.length > 0 && this.filteredSuppliers.length === 0;
    }

    get filteredAgencies() {
        if (!this.agencyList) return [];
        const q = this.agencySearch.toLowerCase();
        return q
            ? this.agencyList.filter(a => a.name.toLowerCase().includes(q) || (a.city || '').toLowerCase().includes(q))
            : this.agencyList;
    }

    get noResults() {
        return this.agencyList && this.agencyList.length > 0 && this.filteredAgencies.length === 0;
    }

    get districtOptions() {
        return [...this.districtMap.values()].map(d => ({
            label: d.Name,
            value: d.SuperDistrictID__c
        }));
    }

    handleDistrictSelect(event) {
        this.handleSuperDistrictClick(event.detail.value);
    }

    async handleSuperDistrictClick(superDistrictId) {
        this.supplierAccount = null;
        this.agencyDetail = null;
        this.hasContacts = false;
        this.selectedSuperDistrict = this.districtMap.get(superDistrictId);
        const suppliers = await getAgencySuppliers({ superDistrictId:  this.selectedSuperDistrict.Id }).catch(error => {
            console.error('Failed to load suppliers:', error);
            this.showErrorToast();
            return [];
        });
        this.supplierList = suppliers.map(s => ({ id: s.Id, name: s.Name }));

        const agencies = await getAgenciesForSuperDistrict({ superDistrictId:  this.selectedSuperDistrict.Id }).catch(error => {
            console.error('Failed to load agencies:', error);
            this.showErrorToast();
            return [];
        });
        this.agencyList = agencies.map(agy => ({id: agy.Id, name: agy.Name}));
        this.template.querySelector('#agency-details')?.scrollIntoView({ behavior: 'smooth', block: 'start' });
        if(this.isMobile){
            const targetSection = his.refs.agencyDiv;            
            if (targetSection) {
                // 3. Smoothly scroll the element into view
                targetSection.scrollIntoView({ 
                    behavior: 'smooth', 
                    block: 'start' 
                });
            }
        }

         
            
    }     

    handleAgencySearchChange(event) {
        this.agencySearch = event.target.value;
    }
   async handleGoToAccount(event) {
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.dataset.id,
                objectApiName: 'Account',
                actionName: 'view'
            }
        }).then((url) => {
            const el = document.createElement('a');
            el.href = url;
            el.target = '_blank';
            el.rel = 'noopener noreferrer';
            el.click(); // Triggers the navigation cleanly
        });
    }


    async handleAgencyListClick(event) {
        const agencyId = event.currentTarget.dataset.id;
        this.supplierAccount = null;
        this.agencyDetail = null;
        this.hasContacts = false;
        this.agencyDetail = await getAccount({ accountId: agencyId });
        this.agencyDetail.contacts.forEach(agy => {
            this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId:  agy.Id,
                objectApiName: 'Contact',
                actionName: 'view'
            }
            }).then(url => {
                this.agencyDetail.contactUrl = url;
            });
        });
        if (this.agencyDetail.contacts?.length > 0){
            this.hasContacts = true;
        }
        console.log("Agency Details: " + this.agencyDetail);
    }    
    async handleContactLinkClick(event){
        event.preventDefault();
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: event.target.dataset.id,
                objectApiName: 'Contact',
                actionName: 'view'
            }
        }).then((url) => {            
            const el = document.createElement('a');
            el.href = url;
            el.target = '_blank';
            el.rel = 'noopener noreferrer';
            el.click(); // Triggers the navigation cleanly
        });
    }
     handleSupplierSearchChange(event) {
        this.supplierSearch = event.target.value;
    }

    async handleSupplierListClick(event) {
        this.agencyDetail = null;
        this.agencyDetails = null;
        const supplierId = event.currentTarget.dataset.id;    
        this.supplierAccount = await getAccount({ accountId: supplierId });   
        const supplierAgencies = await getSupplierAgencies({ supplierAccountId: supplierId,superDistrictId:  this.selectedSuperDistrict.Id })
                            .catch(error => {
                                console.error('Failed to load agencies:', error);
                                this.showErrorToast();
                                return [];
                            });
        const agencyIds = supplierAgencies.map(a => a.Id);
        const rawAgencies = await getAgencies({ accountIds: agencyIds });
        this.agencyDetails = await Promise.all(
            rawAgencies.map(async a => {
                const contacts = await Promise.all(
                    (a.Contacts || []).map(async c => {
                        const url = await this[NavigationMixin.GenerateUrl]({
                            type: 'standard__recordPage',
                            attributes: { recordId: c.Id, objectApiName: 'Contact', actionName: 'view' }
                        });
                        return { ...c, contactUrl: url };
                    })
                );
                return { ...a, Contacts: contacts, hasContacts: contacts.length > 0 };
            })
        );     
        console.log("Agency Details: " + this.agencyDetail);
    }

    showErrorToast() {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: 'Something went wrong, if the issue persist, please contact support.',
            variant: 'error'
        }));
    }

    handleReset() {
        this.agencyMarkers.forEach(m => m.remove());
        this.agencyMarkers = [];
        this.agencyLocationMap = new Map();
        this.agencyDetail = null;
        this.agencyList = null;
        this.agencySearch = '';
        this.supplierList = null;
        this.supplierSearch = '';
        this.districtOptions();
        this.setMap(this.centerUsLat, this.centerUsLon, this.defaultZoom);
    }
}