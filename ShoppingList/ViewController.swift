//
//  ViewController.swift
//  ShoppingList
//
//  Created by Abdulsamet Bakmaz on 2.09.2022.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource { //table view için gerekli kütüphaneler ve aşağıda fonksiyonlarını eklememiz gerekmekte
    
    var nameArray = [String]()
    var idArray = [UUID]()
    var selectedName = ""
    var selectedUUID : UUID?

    @IBOutlet weak var tableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad() //sayfa ilk açıldığında çalışır

        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButtonClicked)) //sağ üstteki + simgesi ve gideceği viewControllerın nasıl kullanıldığı
        getData()
    }
    override func viewWillAppear(_ animated: Bool) { // sayfa her açıldığında yeniden yüklemesi için gerekli olan load fonksiyonu viewWillAppear
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name(rawValue:"veriGirildi"), object: nil)//detailsView deki kaydedilen verileri göstermesi için eşleştirdik
    }
    
    @objc func getData(){
        nameArray.removeAll(keepingCapacity: false)//arrayları boşaltır
        idArray.removeAll(keepingCapacity: false)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Shoppings")
        fetchRequest.returnsObjectsAsFaults = false //çok büyük verileri çekerken cache mekanizmasından faydalanabilmek için bu kısmı false yapıyoruz
        do{
            let results = try context.fetch(fetchRequest)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    if let name = result.value(forKey: "isim") as? String{
                        nameArray.append(name)
                    }
                    if let id = result.value(forKey: "id") as? UUID{
                        idArray.append(id)
                    }
                }
                tableView.reloadData()
            }
            
        }catch{
            print("hata var")
        }
    }

    @objc func addButtonClicked(){
        selectedName = ""
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { //kaç adet row olacak -> (yukarıda bizden istenen fonksiyonlardan bir tanesi )
        
        return nameArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell { //bu rowlarda ne gösterilecek -> (yukarıda bizden istenen fonksiyonlardan bir tanesi)
        let cell = UITableViewCell()
        cell.textLabel?.text = nameArray[indexPath.row]
        return cell
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetailsVC" {
            let destinationVC = segue.destination as! DetailsViewController
            destinationVC.selectedProductName = selectedName
            destinationVC.selectedProductUUID = selectedUUID
        }
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedName = nameArray[indexPath.row]
        selectedUUID = idArray[indexPath.row]
        performSegue(withIdentifier: "toDetailsVC", sender: nil)
    }
    func tableView(_ tableView: UITableView, commit editingStyle : UITableViewCell.EditingStyle, forRowAt indexPath : IndexPath){//UI'da ilgili indexteki veriyi silmek için yapılır ama asıl işlem veri tabanından da silmek onuda aşağıdaki bloklarda yapacağız
        if  editingStyle == .delete{
            //ilgilşi veriyi uuid iie önce veritabanından çekeceğiz sonra o uuid ile onu sileceğiz
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Shoppings") // veritabanına fetchRequest ile bağlandık
            let uuidString = idArray[indexPath.row].uuidString
            fetchRequest.predicate = NSPredicate.init(format: "id = %@", uuidString)//uuid yi burada filtreliyoruz
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchRequest) //context.fetch ile fetchRequeste çektiğin core data verilerini results a ata
                if results.count>0{ //results eğer boş değilse if e gir
                    for result in results as! [NSManagedObject]{ // resultstaki verilerin her birini result ta NSManagedOnject yardııyla tut
                        if let id = result.value(forKey: "id") as? UUID{ //eğer resultsun tuttuğu id ile UUID aynıysa  sonucu id değişkenine ata ve if e gir
                            if id == idArray[indexPath.row]{ //eğer id ile idArrayindeki gelen indexe göre id eşleşirse silme işlemi için if e gir
                                context.delete(result) //context.delete ile core datadan gelen id yi sil
                                nameArray.remove(at: indexPath.row) //bu indexe göre name arraydan veriyi sil
                                idArray.remove(at: indexPath.row) //bu indexe göre idArraydan bu veriyi sil
                                self.tableView.reloadData() //tableView'ı yebile ve güncel halini göster
                                do{
                                    try context.save() //coreDatanın son halini save et
                                }catch{
                                    print("veri silinemedi")
                                }
                                break // bu for loopu tekrar tekrar döndürmemek için break et yani durdur
                            }
                        }
                    }
                }
                
            }catch{
                print("hata")
            }
            
        }
    }
}

